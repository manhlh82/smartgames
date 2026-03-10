import Foundation

/// A single analytics event with name and parameters.
struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]

    init(name: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}
