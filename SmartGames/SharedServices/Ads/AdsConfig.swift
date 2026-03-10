import Foundation

/// Centralized ad unit ID configuration.
/// Debug uses Google's official test IDs — production uses build config.
enum AdsConfig {
    static var rewardedAdUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/1712485313" // Official test ID
        #else
        // Production ID injected via xcconfig — never hardcoded
        return Bundle.main.object(forInfoDictionaryKey: "ADS_REWARDED_ID") as? String
               ?? "ca-app-pub-3940256099942544/1712485313"
        #endif
    }

    static var interstitialAdUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/4411468910" // Official test ID
        #else
        return Bundle.main.object(forInfoDictionaryKey: "ADS_INTERSTITIAL_ID") as? String
               ?? "ca-app-pub-3940256099942544/4411468910"
        #endif
    }

    /// Maximum interstitials to show per session (v1: conservative limit).
    static let maxInterstitialsPerSession = 1

    /// Minimum seconds between interstitial attempts.
    static let interstitialCooldownSeconds = 60
}
