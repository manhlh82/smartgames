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
    static let adWatchDailyMax = 5

    // MARK: - Gold: Daily Login Rewards (day 1–7+, index 0 = day 1)

    /// Gold amounts indexed by streak day (0-based). Day 7+ loops to last value.
    static let dailyLoginGoldRewards = [100, 150, 200, 250, 300, 350, 400]

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

    /// Compute gold for a merge resulting in `tileValue`. Returns 0 for tiles < 4.
    static func mergeGold(resultTileValue: Int) -> Int {
        guard resultTileValue >= 4 else { return 0 }
        let exponent = Int(log2(Double(resultTileValue))) - 2   // 4→0, 8→1, 16→2, …
        let reward = mergeBaseGold * (1 << exponent)
        return min(reward, mergeGoldCap)
    }
}
