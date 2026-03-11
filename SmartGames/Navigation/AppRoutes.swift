import Foundation

/// All navigable routes in the app.
enum AppRoute: Hashable {
    /// Hub card tapped — navigate to game lobby.
    case gameLobby(gameId: String)
    /// In-game navigation — context string decoded by the game module.
    /// For Sudoku: difficulty rawValue ("easy"/"medium"/"hard"/"expert"),
    ///             "daily" for daily challenge, "statistics" for stats view.
    case gamePlay(gameId: String, context: String)
    case settings
}
