import Foundation
import os.log

/// Protocol enabling testing and swapping analytics backends.
protocol AnalyticsServiceProtocol: AnyObject {
    func log(_ event: AnalyticsEvent)
}

/// Analytics service — logs to console in DEBUG.
/// TODO: Replace with Firebase Analytics when SDK is installed:
///   1. Add FirebaseAnalytics via SPM in Xcode
///   2. Add FirebaseApp.configure() to SmartGamesApp
///   3. Replace print with: Analytics.logEvent(event.name, parameters: event.parameters as? [String: Any])
final class AnalyticsService: ObservableObject, AnalyticsServiceProtocol {
    private let logger = Logger(subsystem: "com.smartgames.app", category: "Analytics")

    func log(_ event: AnalyticsEvent) {
        #if DEBUG
        let paramsStr = event.parameters.isEmpty ? "" : " \(event.parameters)"
        logger.debug("[Analytics] \(event.name)\(paramsStr)")
        #endif
        // Production: Firebase.Analytics.logEvent(event.name, parameters: event.parameters)
    }

    /// Log multiple events at once.
    func log(_ events: AnalyticsEvent...) {
        events.forEach { log($0) }
    }
}
