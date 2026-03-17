import Foundation

/// Diamond currency analytics events.
extension AnalyticsEvent {

    // MARK: - Earn

    static func diamondEarned(amount: Int, source: String, balanceAfter: Int) -> AnalyticsEvent {
        AnalyticsEvent("diamond_earned", [
            "amount": amount,
            "source": source,
            "balance_after": balanceAfter
        ])
    }

    // MARK: - Spend

    static func diamondSpent(amount: Int, reason: String, balanceAfter: Int) -> AnalyticsEvent {
        AnalyticsEvent("diamond_spent", [
            "amount": amount,
            "reason": reason,
            "balance_after": balanceAfter
        ])
    }

    // MARK: - Drop Roll (for tuning drop rate)

    /// Fired every time a big-merge drop is rolled — records outcome for rate calibration.
    static func diamondDropRolled(tileValue: Int, didDrop: Bool) -> AnalyticsEvent {
        AnalyticsEvent("diamond_drop_rolled", [
            "tile_value": tileValue,
            "did_drop": didDrop
        ])
    }
}
