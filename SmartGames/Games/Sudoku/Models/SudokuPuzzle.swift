import Foundation

/// A complete Sudoku puzzle with its current board state.
struct SudokuPuzzle: Codable, Identifiable {
    let id: String
    let difficulty: SudokuDifficulty
    let givens: [[Int]]       // 9x9 grid — 0 = empty, 1-9 = given
    let solution: [[Int]]     // 9x9 complete solution
    var board: [[SudokuCell]] // current mutable game state

    /// Create a puzzle from givens and solution grids.
    init(id: String = UUID().uuidString, difficulty: SudokuDifficulty, givens: [[Int]], solution: [[Int]]) {
        self.id = id
        self.difficulty = difficulty
        self.givens = givens
        self.solution = solution
        // Build the initial board from givens
        self.board = (0..<9).map { row in
            (0..<9).map { col in
                let v = givens[row][col]
                return SudokuCell(row: row, col: col, value: v == 0 ? nil : v, isGiven: v != 0)
            }
        }
    }

    /// Number of empty cells remaining (for progress tracking).
    var emptyCellCount: Int {
        board.flatMap { $0 }.filter { $0.value == nil }.count
    }

    /// Total cells the player needs to fill (based on original givens).
    var totalEmptyCells: Int {
        givens.flatMap { $0 }.filter { $0 == 0 }.count
    }
}
