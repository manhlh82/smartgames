import Foundation
import SwiftUI

@MainActor
final class HubViewModel: ObservableObject {
    @Published var games: [GameEntry] = []

    func loadGames(from registry: GameRegistry) {
        games = registry.allGames.map { module in
            GameEntry(
                id: module.id,
                displayName: module.displayName,
                iconName: module.iconName,
                isAvailable: module.isAvailable
            )
        }
    }
}
