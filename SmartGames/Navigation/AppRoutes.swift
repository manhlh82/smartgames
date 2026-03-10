import Foundation

/// All navigable routes in the app.
enum AppRoute: Hashable {
    case sudokuLobby
    case sudokuGame(difficulty: String)
    case settings
}
