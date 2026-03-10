import Foundation

@MainActor
final class HubViewModel: ObservableObject {
    /// All registered games. Add entries here as new games ship.
    @Published var games: [GameEntry] = [
        GameEntry(
            id: "sudoku",
            displayName: "Sudoku",
            iconAsset: "icon-sudoku",
            isAvailable: true
        )
    ]
}
