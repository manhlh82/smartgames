import Foundation

/// Conversion funnel and high-conversion feature analytics events.
/// Use these to measure ad-watch→IAP uplift, time-to-first-purchase, and popup effectiveness.
extension AnalyticsEvent {

    // MARK: - Generic Popup Funnel

    static func popupShown(type: String) -> AnalyticsEvent {
        AnalyticsEvent("popup_shown", ["type": type])
        // type: "starter_pack", "timed_sale", "daily_login", "skip_ads_banner"
    }

    static func popupDismissed(type: String) -> AnalyticsEvent {
        AnalyticsEvent("popup_dismissed", ["type": type])
    }

    static func ctaClicked(type: String, action: String) -> AnalyticsEvent {
        AnalyticsEvent("cta_clicked", [
            "type": type,       // popup/banner type
            "action": action    // "purchase", "watch_ad", "dismiss", "shop_now"
        ])
    }

    // MARK: - Ad→IAP Conversion

    /// Fired when user initiates IAP in the same session where they watched N ads.
    static func adToIAPConversion(sessionAdCount: Int, productId: String) -> AnalyticsEvent {
        AnalyticsEvent("ad_to_iap_conversion", [
            "session_ad_count": sessionAdCount,
            "product_id": productId
        ])
    }

    /// Fired when "Skip ads with diamonds" CTA is shown after threshold.
    static func skipAdsCTAShown(sessionAdCount: Int) -> AnalyticsEvent {
        AnalyticsEvent("skip_ads_cta_shown", ["session_ad_count": sessionAdCount])
    }

    /// Fired when "Remove ads" banner is shown after daily threshold.
    static func removeAdsBannerShown(dailyAdCount: Int) -> AnalyticsEvent {
        AnalyticsEvent("remove_ads_banner_shown", ["daily_ad_count": dailyAdCount])
    }

    // MARK: - Timed Sale

    static func timedSaleShown(trigger: String, consecutiveLosses: Int) -> AnalyticsEvent {
        AnalyticsEvent("timed_sale_shown", [
            "trigger": trigger,                          // "consecutive_losses", "session_timer"
            "consecutive_losses": consecutiveLosses
        ])
    }

    static let timedSalePurchased = AnalyticsEvent("timed_sale_purchased")

    static func timedSaleDismissed(secondsRemaining: Int) -> AnalyticsEvent {
        AnalyticsEvent("timed_sale_dismissed", ["seconds_remaining": secondsRemaining])
    }

    // MARK: - Daily Login

    static func dailyLoginClaimed(streakDay: Int, goldAmount: Int, diamondAmount: Int) -> AnalyticsEvent {
        AnalyticsEvent("daily_login_claimed", [
            "streak_day": streakDay,
            "gold_amount": goldAmount,
            "diamond_amount": diamondAmount
        ])
    }

    // MARK: - Social Share

    static func socialShareInitiated(score: Int, gameId: String) -> AnalyticsEvent {
        AnalyticsEvent("social_share_initiated", [
            "score": score,
            "game_id": gameId
        ])
    }

    static func socialShareCompleted(goldEarned: Int, diamondEarned: Int) -> AnalyticsEvent {
        AnalyticsEvent("social_share_completed", [
            "gold_earned": goldEarned,
            "diamond_earned": diamondEarned
        ])
    }

    // MARK: - A/B Test Assignment

    static func abTestAssigned(testName: String, variant: String) -> AnalyticsEvent {
        AnalyticsEvent("ab_test_assigned", [
            "test_name": testName,
            "variant": variant
        ])
    }
}
