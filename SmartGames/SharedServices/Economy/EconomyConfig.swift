import Foundation

/// Centralised economy constants — all values intended to be overridable via RemoteEconomyConfig.
/// Values here are the default fallbacks.
enum EconomyConfig {

    // MARK: - Gold: Merge Rewards

    /// Base gold granted for a 2→4 merge. Doubles per tile-value tier.
    static let mergeBaseGold = 10
    /// Formula: mergeBaseGold * 2^(log2(resultTile) - 2), capped at mergeGoldCap.
    /// e.g. 2→4=10, 4→8=20, 8→16=40, 16→32=80, 32→64=160, 64→128=320, ≥128→512 cap.
    static let mergeGoldCap = 512

    // MARK: - Gold: Move Streak

    /// Grant moveStreakBonus gold every N valid moves.
    static let moveStreakInterval = 5
    static let moveStreakBonus = 5

    // MARK: - Gold: Rewarded Ad

    /// Gold granted per rewarded ad watch.
    static let adWatchGold = 50
    /// Maximum ad-watch gold grants per calendar day.
    static let adWatchDailyMax = 4

    // MARK: - Gold: Daily Login Rewards (day 1–7+, index 0 = day 1)

    /// Gold amounts indexed by streak day (0-based). Day 7+ loops to last value.
    /// Rebalanced: less early, more on day 7 to reward dedication.
    static let dailyLoginGoldRewards = [50, 100, 150, 200, 250, 300, 500]

    // MARK: - Login Streak Grace Period

    /// Max missed-day grace uses per 7-day cycle (keeps streak alive for 1 missed day).
    static let loginStreakMaxGracePerCycle = 1

    // MARK: - Onboarding

    /// Diamonds granted on first app launch to demonstrate hard currency value.
    static let onboardingDiamondGrant = 5

    // MARK: - Gold: Daily Challenge Rewards

    /// Base gold for completing any game's daily challenge.
    static let dailyChallengeCompleteGold = 25
    /// Bonus gold for 3-star completion of daily challenge.
    static let dailyChallengeThreeStarBonus = 25

    // MARK: - Gold: Stack 2048 Challenge Mode

    /// Base gold for completing a challenge level (1-star).
    static let stack2048ChallengeCompleteGold = 15
    /// Additional gold per extra star above 1-star.
    static let stack2048ChallengeStarBonus = 10

    // MARK: - Weekly Challenge Rewards

    /// Gold + diamond rewards per placement tier. Key = tier name.
    static let weeklyRewardTiers: [String: (gold: Int, diamonds: Int)] = [
        "top1":          (500, 3),
        "top5":          (300, 1),
        "top25":         (150, 0),
        "top50":         (50,  0),
        "participation": (25,  0),
    ]
    /// Minimum player count for tiered rewards (below this, everyone gets participation).
    static let weeklyMinPlayersForTiers = 10

    // MARK: - Diamonds: Drop Rates (moved from DiamondReward for remote-config parity)

    /// Probability to drop 1 diamond after watching a rewarded ad.
    static let adDiamondDropChance: Double = 0.002   // 0.2%

    // MARK: - Ads: Conversion

    /// Session ad-watch count threshold to show "Skip ads with diamonds" CTA.
    static let sessionAdWatchSkipCTAThreshold = 2
    /// Daily ad-watch count threshold to show "Remove Ads" banner.
    static let dailyAdWatchRemoveBannerThreshold = 3

    // MARK: - High-Conversion Features

    static let socialShareGold = 25
    static let socialShareDiamondChance: Double = 0.001
    static let timeLimitedSaleDuration: TimeInterval = 3600     // 1 hour
    static let starterPackSessionTimerSeconds: Double = 300     // 5 min
    static let consecutiveLossesForSale = 2
    static let consecutiveLossesForStarterPack = 1
    static let piggyBankNudgeThreshold: Double = 0.8            // 80% full

    // MARK: - Helpers

    /// Difficulty-scaled gold reward for completing a puzzle/level.
    /// - Parameters:
    ///   - game: "sudoku", "dropRush", or "stack2048"
    ///   - difficulty: SudokuDifficulty.rawValue for Sudoku; level number string for Drop Rush
    static func levelCompleteGold(game: String, difficulty: String) -> Int {
        switch game {
        case "sudoku":
            switch difficulty {
            case "easy":   return 15
            case "medium": return 25
            case "hard":   return 40
            case "expert": return 60
            default:       return 15
            }
        case "dropRush":
            let level = Int(difficulty) ?? 1
            // base 10 + 5 per 10 levels, capped at 50
            return min(10 + (level / 10) * 5, 50)
        case "crossword":
            return 20 // flat reward for all difficulties
        default:
            return 10
        }
    }

    /// Compute gold for a merge resulting in `tileValue`. Returns 0 for tiles < 4.
    static func mergeGold(resultTileValue: Int) -> Int {
        guard resultTileValue >= 4 else { return 0 }
        let exponent = Int(log2(Double(resultTileValue))) - 2   // 4→0, 8→1, 16→2, …
        let reward = mergeBaseGold * (1 << exponent)
        return min(reward, mergeGoldCap)
    }
}
