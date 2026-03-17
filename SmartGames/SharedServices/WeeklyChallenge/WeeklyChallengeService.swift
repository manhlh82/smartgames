import Foundation

/// Manages weekly challenge state: score tracking, leaderboard submission, and reward claiming.
/// Uses NotificationCenter to receive scores from game VMs without tight coupling.
@MainActor
final class WeeklyChallengeService: ObservableObject {
    /// Set when previous-week rewards are ready to display; cleared after UI claims.
    @Published var pendingRewards: WeeklyRewardResult? = nil

    private let persistence: PersistenceService
    private let goldService: GoldService
    private let diamondService: DiamondService
    private let gameCenter: GameCenterService

    private var observer: NSObjectProtocol?

    init(
        persistence: PersistenceService,
        goldService: GoldService,
        diamondService: DiamondService,
        gameCenter: GameCenterService
    ) {
        self.persistence = persistence
        self.goldService = goldService
        self.diamondService = diamondService
        self.gameCenter = gameCenter
    }

    // MARK: - Lifecycle

    /// Call on app launch. Detects week rollover and triggers reward claiming for the previous week.
    func onAppLaunch() {
        let currentWeek = Self.currentWeekID()
        let saved = loadState()

        if saved.weekIdentifier != currentWeek {
            // Week rolled over — claim rewards for the old week if not yet claimed
            if !saved.rewardsClaimed {
                Task { await self.claimRewards(for: saved) }
            }
            // Start fresh state for new week
            let newState = WeeklyChallengeState(weekIdentifier: currentWeek)
            saveState(newState)
        }
    }

    /// Register NotificationCenter observer to receive scores from game VMs.
    func startObservingScores() {
        observer = NotificationCenter.default.addObserver(
            forName: .weeklyScoreOccurred,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let game = notification.userInfo?["game"] as? String,
                let score = notification.userInfo?["score"] as? Int
            else { return }
            Task { @MainActor [weak self] in
                self?.submitScore(game: game, score: score)
            }
        }
    }

    // MARK: - Score Submission

    /// Update local best score and submit to Game Center weekly leaderboard.
    func submitScore(game: String, score: Int) {
        guard score > 0 else { return }
        var state = loadState()
        let currentBest = state.bestScores[game] ?? 0
        guard score > currentBest else { return }
        state.bestScores[game] = score
        saveState(state)

        let leaderboardID = GameCenterService.WeeklyLeaderboardID.id(for: game)
        gameCenter.submitScore(score, leaderboardID: leaderboardID)
    }

    /// Called after the UI has presented and dismissed the weekly reward popup.
    func clearPendingRewards() {
        pendingRewards = nil
    }

    // MARK: - Reward Claiming

    private func claimRewards(for state: WeeklyChallengeState) async {
        let games = Array(state.bestScores.keys)
        guard !games.isEmpty else { return }

        var gameRewards: [WeeklyGameReward] = []

        for game in games {
            let leaderboardID = GameCenterService.WeeklyLeaderboardID.id(for: game)
            let rankInfo = await gameCenter.fetchWeeklyRank(leaderboardID: leaderboardID)

            let tier: WeeklyRewardTier
            if let info = rankInfo, info.totalPlayers >= EconomyConfig.weeklyMinPlayersForTiers {
                tier = Self.tierForRank(info.rank, total: info.totalPlayers)
            } else {
                tier = .participation
            }

            let rewards = EconomyConfig.weeklyRewardTiers[tier.rawValue] ?? (gold: 25, diamonds: 0)
            goldService.earn(amount: rewards.gold)
            if rewards.diamonds > 0 {
                diamondService.earn(amount: rewards.diamonds)
            }

            gameRewards.append(WeeklyGameReward(
                game: game, tier: tier,
                gold: rewards.gold, diamonds: rewards.diamonds
            ))
        }

        // Mark rewards claimed in persisted state (current week may differ — re-read to avoid stale write)
        var current = loadState()
        if current.weekIdentifier == state.weekIdentifier {
            current.rewardsClaimed = true
            saveState(current)
        }

        pendingRewards = WeeklyRewardResult(gameRewards: gameRewards)
    }

    // MARK: - Helpers

    static func currentWeekID() -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let week = cal.component(.weekOfYear, from: Date())
        let year = cal.component(.yearForWeekOfYear, from: Date())
        return "\(year)-W\(String(format: "%02d", week))"
    }

    private static func tierForRank(_ rank: Int, total: Int) -> WeeklyRewardTier {
        let ratio = Double(rank) / Double(total)
        if ratio <= 0.01  { return .top1 }
        if ratio <= 0.05  { return .top5 }
        if ratio <= 0.25  { return .top25 }
        if ratio <= 0.50  { return .top50 }
        return .participation
    }

    private func loadState() -> WeeklyChallengeState {
        persistence.load(WeeklyChallengeState.self, key: PersistenceService.Keys.weeklyChallenge)
            ?? WeeklyChallengeState(weekIdentifier: Self.currentWeekID())
    }

    private func saveState(_ state: WeeklyChallengeState) {
        persistence.save(state, key: PersistenceService.Keys.weeklyChallenge)
    }
}
