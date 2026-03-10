import Foundation

/// A single cell in the 9x9 Sudoku grid.
struct SudokuCell: Codable, Equatable, Identifiable {
    var id: String { "\(row)-\(col)" }
    let row: Int
    let col: Int
    var value: Int?           // nil = empty, 1-9 = filled
    let isGiven: Bool         // pre-filled clue — cannot be changed by player
    var pencilMarks: Set<Int> // candidate notes when in pencil mode
    var hasError: Bool        // true when the placed value conflicts

    init(row: Int, col: Int, value: Int? = nil, isGiven: Bool = false) {
        self.row = row
        self.col = col
        self.value = value
        self.isGiven = isGiven
        self.pencilMarks = []
        self.hasError = false
    }

    /// Whether this cell is empty and can accept a player move.
    var isEmpty: Bool { value == nil && !isGiven }

    /// Whether this cell has been filled by the player (not a given).
    var isPlayerFilled: Bool { value != nil && !isGiven }
}

/// Position identifier for a board cell.
struct CellPosition: Hashable, Codable {
    let row: Int
    let col: Int
}
