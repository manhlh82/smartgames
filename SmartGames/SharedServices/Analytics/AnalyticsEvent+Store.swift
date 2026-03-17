import Foundation

/// IAP store and purchase funnel analytics events.
extension AnalyticsEvent {

    // MARK: - IAP Purchase Funnel

    static func iapPurchaseInitiated(productId: String) -> AnalyticsEvent {
        AnalyticsEvent("iap_purchase_initiated", ["product_id": productId])
    }

    static func iapPurchaseCompleted(productId: String, price: String, currency: String) -> AnalyticsEvent {
        AnalyticsEvent("iap_purchase_completed", [
            "product_id": productId,
            "price": price,
            "currency": currency
        ])
    }

    static func iapPurchaseFailed(productId: String, reason: String) -> AnalyticsEvent {
        AnalyticsEvent("iap_purchase_failed", [
            "product_id": productId,
            "reason": reason   // "user_cancelled", "payment_invalid", "not_allowed", "unknown"
        ])
    }

    static func iapRestoreCompleted(restoredCount: Int) -> AnalyticsEvent {
        AnalyticsEvent("iap_restore_completed", ["restored_count": restoredCount])
    }

    // MARK: - Store View

    static let storeViewOpened = AnalyticsEvent("store_view_opened")

    static func storeItemImpression(productId: String) -> AnalyticsEvent {
        AnalyticsEvent("store_item_impression", ["product_id": productId])
    }

    // MARK: - Starter Pack

    static let starterPackShown = AnalyticsEvent("starter_pack_shown")
    static let starterPackPurchased = AnalyticsEvent("starter_pack_purchased")
    static let starterPackDismissed = AnalyticsEvent("starter_pack_dismissed")

    // MARK: - Piggy Bank

    static func piggyBankUnlocked(diamondsGranted: Int) -> AnalyticsEvent {
        AnalyticsEvent("piggy_bank_unlocked", ["diamonds_granted": diamondsGranted])
    }

    static func piggyBankNudgeShown(fillFraction: Double) -> AnalyticsEvent {
        AnalyticsEvent("piggy_bank_nudge_shown", [
            "fill_pct": Int(fillFraction * 100)
        ])
    }

    // MARK: - Themes

    static func themePurchasedGold(themeName: String, goldSpent: Int) -> AnalyticsEvent {
        AnalyticsEvent("theme_purchased_gold", [
            "theme_name": themeName,
            "gold_spent": goldSpent
        ])
    }

    static func themePurchasedDiamond(themeName: String, diamondsSpent: Int) -> AnalyticsEvent {
        AnalyticsEvent("theme_purchased_diamond", [
            "theme_name": themeName,
            "diamonds_spent": diamondsSpent
        ])
    }
}
