import Foundation

/// Monetization / ads analytics events.
extension AnalyticsEvent {

    // MARK: - Banner Events

    static func adBannerLoaded(gameId: String) -> AnalyticsEvent {
        AnalyticsEvent("ad_banner_loaded", ["game_id": gameId])
    }

    static func adBannerLoadFailed(gameId: String, errorCode: Int = 0) -> AnalyticsEvent {
        AnalyticsEvent("ad_banner_load_failed", [
            "game_id": gameId,
            "error_code": errorCode
        ])
    }

    static func adBannerClicked(gameId: String) -> AnalyticsEvent {
        AnalyticsEvent("ad_banner_clicked", ["game_id": gameId])
    }

    static func adBannerImpression(gameId: String) -> AnalyticsEvent {
        AnalyticsEvent("ad_banner_impression", ["game_id": gameId])
    }

    // MARK: - Ad Unavailable

    static func adUnavailable(adType: String, reason: String, context: String) -> AnalyticsEvent {
        AnalyticsEvent("ad_unavailable", [
            "ad_type": adType,    // "rewarded", "interstitial", "banner"
            "reason": reason,     // "not_loaded", "load_failed"
            "context": context    // "hints", "mistake_reset", "continue", "post_level"
        ])
    }

    // MARK: - Interstitial Skipped

    static func adInterstitialSkipped(reason: String) -> AnalyticsEvent {
        AnalyticsEvent("ad_interstitial_skipped", ["reason": reason])
        // reason: "not_ready", "ads_removed", "frequency_not_met"
    }

    // MARK: - Rewarded

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
