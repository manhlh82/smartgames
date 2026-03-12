import Foundation

/// Centralized ad unit ID configuration.
/// Debug uses Google's official test IDs — production uses build config.
/// Rate-limiting and frequency config moved to MonetizationConfig (per-game).
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

    static var bannerAdUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2435281174" // Official test banner ID
        #else
        return Bundle.main.object(forInfoDictionaryKey: "ADS_BANNER_ID") as? String
               ?? "ca-app-pub-3940256099942544/2435281174"
        #endif
    }
}
