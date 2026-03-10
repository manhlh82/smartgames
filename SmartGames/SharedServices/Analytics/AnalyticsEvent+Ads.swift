import Foundation

/// Monetization / ads analytics events.
extension AnalyticsEvent {

    static func adRewardedPromptShown(reason: String, difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("ad_rewarded_prompt_shown", [
            "reason": reason,
            "difficulty": difficulty
        ])
    }

    static func adRewardedAccepted(reason: String) -> AnalyticsEvent {
        AnalyticsEvent("ad_rewarded_accepted", ["reason": reason])
    }

    static func adRewardedDeclined(reason: String) -> AnalyticsEvent {
        AnalyticsEvent("ad_rewarded_declined", ["reason": reason])
    }

    static func adRewardedCompleted(reason: String) -> AnalyticsEvent {
        AnalyticsEvent("ad_rewarded_completed", ["reason": reason])
    }

    static func adRewardedFailed(reason: String, errorCode: Int = 0) -> AnalyticsEvent {
        AnalyticsEvent("ad_rewarded_failed", [
            "reason": reason,
            "error_code": errorCode
        ])
    }

    static let adInterstitialShown = AnalyticsEvent("ad_interstitial_shown")

    static func adInterstitialDismissed(watchedSeconds: Int) -> AnalyticsEvent {
        AnalyticsEvent("ad_interstitial_dismissed", ["watched_seconds": watchedSeconds])
    }
}
