import Foundation

/// Tracks daily login streaks and grants gold (and diamonds on day 7) on each new calendar day.
/// Call `checkAndGrantLoginReward()` on app foreground / launch.
@MainActor
final class DailyLoginRewardService: ObservableObject {

    /// Set to a reward when a new-day grant occurs; consumers observe this to show the popup.
    @Published var pendingReward: LoginReward? = nil

    private let persistence: PersistenceService
    private let goldService: GoldService
    private let diamondService: DiamondService

    init(persistence: PersistenceService, goldService: GoldService, diamondService: DiamondService) {
        self.persistence = persistence
        self.goldService = goldService
        self.diamondService = diamondService
    }

    // MARK: - Public API

    /// Current login streak count (1-based: 1 = first day).
    var streakCount: Int {
        persistence.load(Int.self, key: PersistenceService.Keys.dailyLoginStreakCount) ?? 0
    }

    /// Check if a new calendar day has elapsed; grant reward if so.
    func checkAndGrantLoginReward() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = persistence.load(Date.self, key: PersistenceService.Keys.dailyLoginLastDate)
            .map { Calendar.current.startOfDay(for: $0) }

        guard lastDate != today else { return }     // already claimed today

        let dayGap = lastDate.map { Calendar.current.dateComponents([.day], from: $0, to: today).day ?? 2 } ?? 2
        let graceUsed = persistence.load(Bool.self, key: PersistenceService.Keys.dailyLoginGraceUsedInCycle) ?? false
        let maxGrace = EconomyConfig.loginStreakMaxGracePerCycle
        let currentStreak = persistence.load(Int.self, key: PersistenceService.Keys.dailyLoginStreakCount) ?? 0

        // Grace period: allow 1 missed day per 7-day cycle without resetting streak
        let newStreak: Int
        let usedGraceThisGrant: Bool
        if dayGap == 1 {
            newStreak = currentStreak + 1
            usedGraceThisGrant = false
        } else if dayGap == 2 && !graceUsed && maxGrace > 0 {
            // Missed exactly 1 day — apply grace, keep streak
            newStreak = currentStreak + 1
            usedGraceThisGrant = true
        } else {
            // Missed 2+ days or grace already used — reset streak
            newStreak = 1
            usedGraceThisGrant = false
        }

        persistence.save(newStreak, key: PersistenceService.Keys.dailyLoginStreakCount)
        persistence.save(Date(), key: PersistenceService.Keys.dailyLoginLastDate)

        // Track grace usage; reset when cycle completes (day 7) or streak resets
        if usedGraceThisGrant {
            persistence.save(true, key: PersistenceService.Keys.dailyLoginGraceUsedInCycle)
        } else if newStreak == 1 || newStreak % 7 == 0 {
            persistence.save(false, key: PersistenceService.Keys.dailyLoginGraceUsedInCycle)
        }

        // Update 7-day claim history for calendar UI
        var history = persistence.load([String].self, key: PersistenceService.Keys.dailyLoginClaimHistory) ?? []
        history.append(DailyLoginRewardService.utcDateString())
        if history.count > 7 { history = Array(history.suffix(7)) }
        persistence.save(history, key: PersistenceService.Keys.dailyLoginClaimHistory)

        let rewardIndex = min(newStreak - 1, EconomyConfig.dailyLoginGoldRewards.count - 1)
        let goldAmount = EconomyConfig.dailyLoginGoldRewards[rewardIndex]
        goldService.earn(amount: goldAmount)

        // Diamond bonus on day 7 (and every 7th day thereafter)
        let earnedDiamond = newStreak % 7 == 0
        if earnedDiamond {
            diamondService.earn(amount: DiamondReward.dailyLoginDay7Amount)
        }

        pendingReward = LoginReward(
            streakDay: newStreak,
            goldAmount: goldAmount,
            diamondAmount: earnedDiamond ? DiamondReward.dailyLoginDay7Amount : 0,
            usedGrace: usedGraceThisGrant
        )
    }

    /// Clears the pending reward after the UI has presented it.
    func clearPendingReward() {
        pendingReward = nil
    }

    // MARK: - Helpers

    /// Current UTC date as "yyyy-MM-dd".
    static func utcDateString(from date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt.string(from: date)
    }
}

// MARK: - LoginReward

struct LoginReward {
    let streakDay: Int
    let goldAmount: Int
    let diamondAmount: Int   // 0 if no diamond bonus
    let usedGrace: Bool      // true if a grace day was applied this grant
}
