import Foundation
import SwiftUI

@MainActor
final class HubViewModel: ObservableObject {
    /// All registered games. Add entries here as new games ship.
    @Published var games: [GameEntry] = [
        GameEntry(
            id: "sudoku",
            displayName: "Sudoku",
            iconAsset: "icon-sudoku",
            isAvailable: true,
            route: .sudokuLobby
        )
        // Future: Add more GameEntry items here for each new game
    ]
}
