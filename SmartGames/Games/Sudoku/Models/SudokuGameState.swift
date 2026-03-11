import Foundation

/// Full game state that can be saved and restored across app launches.
struct SudokuGameState: Codable {
    let puzzle: SudokuPuzzle
    let elapsedSeconds: Int
    let mistakeCount: Int
    let hintsRemaining: Int
    let hintsUsedTotal: Int
    let undoStack: [BoardSnapshot]
}

/// A snapshot of the board at a point in time — used for undo.
struct BoardSnapshot: Codable {
    let board: [[SudokuCell]]
    let mistakeCount: Int
}

/// Per-difficulty statistics.
struct SudokuStats: Codable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var bestTimeSeconds: Int = Int.max
    var totalMistakes: Int = 0
    // Added in v2 — defaults ensure backward-compatible decoding of existing data
    var totalTimeSeconds: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
}
