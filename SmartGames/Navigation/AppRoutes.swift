import Foundation

/// All navigable routes in the app.
enum AppRoute: Hashable {
    case sudokuLobby
    case sudokuGame(difficulty: SudokuDifficulty)
    case settings
}

// Temporary placeholder until PR-04 defines SudokuDifficulty in the Sudoku module.
// This will be moved to SmartGames/Games/Sudoku/Models/SudokuDifficulty.swift in PR-04.
enum SudokuDifficulty: String, Hashable, Codable, CaseIterable {
    case easy, medium, hard, expert

    var displayName: String { rawValue.capitalized }
}
