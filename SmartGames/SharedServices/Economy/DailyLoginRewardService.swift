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
        // Reset streak if more than 1 day gap
        let newStreak: Int
        if dayGap > 1 {
            newStreak = 1
        } else {
            newStreak = (persistence.load(Int.self, key: PersistenceService.Keys.dailyLoginStreakCount) ?? 0) + 1
        }

        persistence.save(newStreak, key: PersistenceService.Keys.dailyLoginStreakCount)
        persistence.save(Date(), key: PersistenceService.Keys.dailyLoginLastDate)

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
            diamondAmount: earnedDiamond ? DiamondReward.dailyLoginDay7Amount : 0
        )
    }

    /// Clears the pending reward after the UI has presented it.
    func clearPendingReward() {
        pendingReward = nil
    }
}

// MARK: - LoginReward

struct LoginReward {
    let streakDay: Int
    let goldAmount: Int
    let diamondAmount: Int   // 0 if no diamond bonus
}
