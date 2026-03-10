import Foundation

protocol AnalyticsServiceProtocol {
    func log(_ event: AnalyticsEvent)
}

/// Analytics stub — logs to console in DEBUG. Full implementation in PR-09.
final class AnalyticsService: ObservableObject, AnalyticsServiceProtocol {
    func log(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[Analytics] \(event.name) — \(event.parameters)")
        #endif
    }
}
