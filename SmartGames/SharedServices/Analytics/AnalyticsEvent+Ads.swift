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

    // MARK: - Mistake Reset Events

    static func mistakeResetPromptShown(difficulty: String, mistakeCount: Int) -> AnalyticsEvent {
        AnalyticsEvent("mistake_reset_prompt_shown", [
            "difficulty": difficulty,
            "mistake_count": mistakeCount
        ])
    }

    static func mistakeResetUsed(difficulty: String, usesThisLevel: Int) -> AnalyticsEvent {
        AnalyticsEvent("mistake_reset_used", [
            "difficulty": difficulty,
            "uses_this_level": usesThisLevel
        ])
    }

    static func mistakeResetDeclined(difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("mistake_reset_declined", ["difficulty": difficulty])
    }
}
