import Foundation

/// Remote-config override layer for EconomyConfig.
/// In production, replace `remoteValue(key:default:)` with Firebase Remote Config lookups.
/// All game code should read economy values from `RemoteEconomyConfig.shared` instead of
/// `EconomyConfig` directly, to allow server-side tweaks without an app update.
///
/// Firebase integration TODO:
///   1. Add FirebaseRemoteConfig via SPM
///   2. Call `RemoteEconomyConfig.shared.fetchAndActivate()` on app launch
///   3. Replace `remoteValue` stubs with `RemoteConfig.remoteConfig()[key].numberValue`
@MainActor
final class RemoteEconomyConfig: ObservableObject {

    static let shared = RemoteEconomyConfig()

    // MARK: - Gold

    var mergeBaseGold: Int         { remoteInt("economy_merge_base_gold",        default: EconomyConfig.mergeBaseGold) }
    var mergeGoldCap: Int          { remoteInt("economy_merge_gold_cap",          default: EconomyConfig.mergeGoldCap) }
    var moveStreakInterval: Int     { remoteInt("economy_move_streak_interval",    default: EconomyConfig.moveStreakInterval) }
    var moveStreakBonus: Int        { remoteInt("economy_move_streak_bonus",       default: EconomyConfig.moveStreakBonus) }
    var adWatchGold: Int           { remoteInt("economy_ad_watch_gold",           default: EconomyConfig.adWatchGold) }
    var adWatchDailyMax: Int       { remoteInt("economy_ad_watch_daily_max",      default: EconomyConfig.adWatchDailyMax) }

    // MARK: - Diamonds

    var adDiamondDropChance: Double { remoteDouble("economy_ad_diamond_drop_chance", default: EconomyConfig.adDiamondDropChance) }

    // MARK: - Conversion Thresholds

    var sessionAdWatchSkipCTAThreshold: Int     { remoteInt("economy_skip_cta_threshold",    default: EconomyConfig.sessionAdWatchSkipCTAThreshold) }
    var dailyAdWatchRemoveBannerThreshold: Int  { remoteInt("economy_remove_banner_threshold", default: EconomyConfig.dailyAdWatchRemoveBannerThreshold) }
    var consecutiveLossesForSale: Int           { remoteInt("economy_consecutive_losses_sale", default: EconomyConfig.consecutiveLossesForSale) }
    var consecutiveLossesForStarterPack: Int    { remoteInt("economy_consecutive_losses_pack", default: EconomyConfig.consecutiveLossesForStarterPack) }
    var timeLimitedSaleDuration: TimeInterval   { remoteDouble("economy_sale_duration",        default: EconomyConfig.timeLimitedSaleDuration) }
    var starterPackSessionTimerSeconds: Double  { remoteDouble("economy_starter_pack_timer",   default: EconomyConfig.starterPackSessionTimerSeconds) }

    // MARK: - A/B Test Variants

    /// Continue price variant: "1" or "2" diamonds.
    var continuePriceVariant: String    { remoteString("ab_continue_price",     default: "2") }
    /// Starter pack price variant: "control" (full price) or "discount" (30% off).
    var starterPackPriceVariant: String { remoteString("ab_starter_pack_price", default: "control") }

    // MARK: - Fetch (stub — replace with Firebase SDK call)

    /// Fetches and activates remote config values.
    /// Stub: no-op until Firebase SDK is integrated.
    func fetchAndActivate() async {
        // TODO: await RemoteConfig.remoteConfig().fetchAndActivate()
        #if DEBUG
        print("[RemoteEconomyConfig] fetchAndActivate — using local defaults (Firebase not integrated)")
        #endif
    }

    // MARK: - Private helpers

    private func remoteInt(_ key: String, default fallback: Int) -> Int {
        // TODO: return RemoteConfig.remoteConfig()[key].numberValue.intValue
        return fallback
    }

    private func remoteDouble(_ key: String, default fallback: Double) -> Double {
        // TODO: return RemoteConfig.remoteConfig()[key].numberValue.doubleValue
        return fallback
    }

    private func remoteString(_ key: String, default fallback: String) -> String {
        // TODO: return RemoteConfig.remoteConfig()[key].stringValue ?? fallback
        return fallback
    }
}
