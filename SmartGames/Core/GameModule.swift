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
    /// Per-game monetization settings — override to customize ad behavior per game.
    var monetizationConfig: MonetizationConfig { get }
    /// Per-game audio configuration — nil means no background music for this game.
    var audioConfig: (any AudioConfig)? { get }
    /// Returns the lobby/entry view, injecting game-specific services as needed
    func makeLobbyView(environment: AppEnvironment) -> AnyView
    /// Returns nil if this module doesn't handle the given route
    func navigationDestination(for route: AppRoute, environment: AppEnvironment) -> AnyView?
}

extension GameModule {
    /// Default monetization config — games override this to provide custom values.
    var monetizationConfig: MonetizationConfig { MonetizationConfig() }
    /// Default: no audio config (future games opt in by overriding).
    var audioConfig: (any AudioConfig)? { nil }
}
