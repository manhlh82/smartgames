import Foundation

/// Per-game monetization configuration.
/// Each GameModule provides its own instance; injected into game view models at runtime.
struct MonetizationConfig {
    // MARK: - Banner
    /// Show a persistent bottom banner ad during gameplay.
    /// Note: banner refresh interval is controlled by AdMob SDK/dashboard, not app-side code.
    var bannerEnabled: Bool = true

    // MARK: - Post-level Interstitial
    /// Show interstitial after level completion.
    var interstitialEnabled: Bool = true
    /// Show interstitial every N completed levels. 1 = every level.
    var interstitialFrequency: Int = 1

    // MARK: - Rewarded Hints
    /// Enable rewarded ads to earn hints.
    var rewardedHintsEnabled: Bool = true
    /// Hints granted per rewarded ad watch.
    var rewardedHintAmount: Int = 3
    /// Hints granted on level completion.
    var levelCompleteHintReward: Int = 1
    /// Maximum hint balance (ad/level grants never exceed this cap).
    /// IAP hint pack bypasses this cap.
    var maxHintCap: Int = 3

    // MARK: - Rewarded Mistake Reset
    /// Enable rewarded ad to reset mistake counter during gameplay.
    var mistakeResetEnabled: Bool = true
    /// Max mistake resets allowed per level.
    var mistakeResetUsesPerLevel: Int = 1
}
