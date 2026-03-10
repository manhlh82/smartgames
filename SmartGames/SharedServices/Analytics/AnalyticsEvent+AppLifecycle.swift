import Foundation

/// App lifecycle analytics events.
extension AnalyticsEvent {
    static func appOpen(isReturningUser: Bool) -> AnalyticsEvent {
        AnalyticsEvent("app_open", ["is_returning_user": isReturningUser])
    }

    static let attPermissionShown = AnalyticsEvent("att_permission_shown")

    static func attPermissionResponse(status: String) -> AnalyticsEvent {
        AnalyticsEvent("att_permission_response", ["status": status])
    }

    static let hubViewed = AnalyticsEvent("hub_viewed")

    static func gameSelected(gameId: String) -> AnalyticsEvent {
        AnalyticsEvent("game_selected", ["game_id": gameId])
    }

    static let settingsOpened = AnalyticsEvent("settings_opened")
}
