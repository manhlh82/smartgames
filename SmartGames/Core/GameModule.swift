import SwiftUI

/// Contract every game module must conform to.
/// Minimal by design — expand only when a second game requires more.
@MainActor
protocol GameModule: AnyObject {
    var id: String { get }
    var displayName: String { get }
    /// SF Symbol or asset name for hub card icon
    var iconName: String { get }
    /// false = "Coming Soon" badge
    var isAvailable: Bool { get }
    /// Returns the lobby/entry view, injecting game-specific services as needed
    func makeLobbyView(environment: AppEnvironment) -> AnyView
    /// Returns nil if this module doesn't handle the given route
    func navigationDestination(for route: AppRoute, environment: AppEnvironment) -> AnyView?
}
