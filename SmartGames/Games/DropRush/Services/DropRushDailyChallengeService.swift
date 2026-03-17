import Foundation

/// Manages the daily Drop Rush challenge — deterministic level selection, streak tracking,
/// completion state persistence, gold rewards, and GameCenter score submission.
@MainActor
final class DropRushDailyChallengeService: ObservableObject {
    @Published var todayState: DropRushDailyChallengeState
    @Published var streak: DropRushDailyStreakData

    private let persistence: PersistenceService
    private let gold: GoldService
    private let gameCenter: GameCenterService

    // MARK: - Init

    init(persistence: PersistenceService, gold: GoldService, gameCenter: GameCenterService) {
        self.persistence = persistence
        self.gold = gold
        self.gameCenter = gameCenter

        let today = DailyChallengeService.utcDateString()
        self.todayState = persistence.load(DropRushDailyChallengeState.self,
                                           key: PersistenceService.Keys.dropRushDailyState)
                          ?? DropRushDailyChallengeState(dateString: today, isCompleted: false)
        self.streak = persistence.load(DropRushDailyStreakData.self,
                                       key: PersistenceService.Keys.dropRushDailyStreak)
                      ?? DropRushDailyStreakData()

        // Reset state if a new day has started
        if todayState.dateString != today {
            todayState = DropRushDailyChallengeState(dateString: today, isCompleted: false)
            persistence.save(todayState, key: PersistenceService.Keys.dropRushDailyState)
        }
    }

    // MARK: - Level Selection

    /// Returns today's deterministic level config based on day-of-week difficulty.
    func todayConfig() -> LevelConfig {
        let today = DailyChallengeService.utcDateString()
        let seed = SeededRandomNumberGenerator.seed(from: today)
        var rng = SeededRandomNumberGenerator(seed: seed)
        let pool = levelPool()
        let index = Int(rng.next() % UInt64(pool.count))
        let levelNumber = pool[index]
        return LevelDefinitions.level(levelNumber) ?? LevelDefinitions.levels[0]
    }

    /// Level pool varies by day of week (UTC).
    /// Mon/Sun → Tutorial (1–5), Tue–Wed → Easy (6–15), Thu–Fri → Medium (16–30), Sat → Easy-Med (11–20)
    func todayDifficultyLabel() -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let weekday = cal.component(.weekday, from: Date())
        switch weekday {
        case 1, 2: return "Easy"       // Sun, Mon
        case 3, 4: return "Medium"     // Tue, Wed
        case 5, 6: return "Hard"       // Thu, Fri
        case 7:    return "Medium"     // Sat
        default:   return "Medium"
        }
    }

    private func levelPool() -> [Int] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let weekday = cal.component(.weekday, from: Date())
        switch weekday {
        case 1, 2: return Array(1...5)    // Sun, Mon — Tutorial
        case 3, 4: return Array(6...15)   // Tue, Wed — Easy
        case 5, 6: return Array(16...30)  // Thu, Fri — Medium
        case 7:    return Array(11...20)  // Sat — Easy-Med
        default:   return Array(6...15)
        }
    }

    // MARK: - Completion

    func isCompletedToday() -> Bool { todayState.isCompleted }

    /// Call when player completes today's daily challenge.
    func markCompleted(score: Int, stars: Int) {
        guard !todayState.isCompleted else { return }
        let today = DailyChallengeService.utcDateString()
        todayState.isCompleted = true
        todayState.score = score
        todayState.stars = stars
        persistence.save(todayState, key: PersistenceService.Keys.dropRushDailyState)

        // Grant gold reward
        var goldAmount = EconomyConfig.dailyChallengeCompleteGold
        if stars >= 3 { goldAmount += EconomyConfig.dailyChallengeThreeStarBonus }
        gold.earn(amount: goldAmount)

        // Submit to GameCenter leaderboard
        gameCenter.submitScore(score, leaderboardID: GameCenterService.DailyLeaderboardID.dropRush)

        updateStreak(today: today)
    }

    // MARK: - Streak

    private func updateStreak(today: String) {
        var updated = streak
        if let last = updated.lastCompletedDate {
            if last == yesterday() {
                updated.currentStreak += 1
            } else if last == today {
                // Already counted — no-op
            } else {
                updated.currentStreak = 1
            }
        } else {
            updated.currentStreak = 1
        }
        updated.bestStreak = max(updated.bestStreak, updated.currentStreak)
        updated.lastCompletedDate = today
        streak = updated
        persistence.save(streak, key: PersistenceService.Keys.dropRushDailyStreak)
    }

    private func yesterday() -> String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return DailyChallengeService.utcDateString(from: yesterday)
    }
}
