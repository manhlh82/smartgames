import Foundation

/// Gold and theme analytics events.
extension AnalyticsEvent {

    // MARK: - Gold

    static func goldEarned(amount: Int, source: String, balanceAfter: Int) -> AnalyticsEvent {
        AnalyticsEvent("gold_earned", [
            "amount": amount,
            "source": source,
            "balance_after": balanceAfter
        ])
    }

    static func goldSpent(amount: Int, item: String, balanceAfter: Int) -> AnalyticsEvent {
        AnalyticsEvent("gold_spent", [
            "amount": amount,
            "item": item,
            "balance_after": balanceAfter
        ])
    }

    // MARK: - Theme

    static func themePurchased(theme: String, price: Int, balanceAfter: Int) -> AnalyticsEvent {
        AnalyticsEvent("theme_purchased", [
            "theme": theme,
            "price": price,
            "balance_after": balanceAfter
        ])
    }

    static func themeSelected(theme: String) -> AnalyticsEvent {
        AnalyticsEvent("theme_selected", ["theme": theme])
    }

    static func themePurchaseFailed(theme: String, reason: String) -> AnalyticsEvent {
        AnalyticsEvent("theme_purchase_failed", [
            "theme": theme,
            "reason": reason
        ])
    }
}
