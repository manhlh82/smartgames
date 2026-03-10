import Foundation

/// Sudoku difficulty levels with associated clue count ranges and display properties.
enum SudokuDifficulty: String, Hashable, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case expert

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    /// Target number of given (pre-filled) clues on the board.
    var targetGivens: Int {
        switch self {
        case .easy:   return 40
        case .medium: return 30
        case .hard:   return 24
        case .expert: return 20
        }
    }

    /// Maximum mistakes before game over (shown in UI as "Mistakes: 0/3").
    var mistakeLimit: Int { 3 }

    /// Free hints available per game.
    var freeHints: Int { 3 }
}
