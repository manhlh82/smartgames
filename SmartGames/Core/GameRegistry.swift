import Foundation

/// Holds all registered game modules. Populated at app launch.
@MainActor
final class GameRegistry: ObservableObject {
    private(set) var modules: [String: any GameModule] = [:]

    func register(_ module: some GameModule) {
        modules[module.id] = module
    }

    var allGames: [any GameModule] {
        Array(modules.values).sorted { $0.id < $1.id }
    }

    func module(for gameId: String) -> (any GameModule)? {
        modules[gameId]
    }
}
