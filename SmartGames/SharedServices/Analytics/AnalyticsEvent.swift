import Foundation

/// A single analytics event with a name and optional parameters.
struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]

    init(_ name: String, _ parameters: [String: Any] = [:]) {
        self.name = name
        self.parameters = parameters
    }

    // Keep old init for backward compat
    init(name: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}
