import Foundation

/// Validates Sudoku board states — move legality, conflict detection, win condition, hints.
final class SudokuValidator {

    /// Check if placing `value` at (row, col) is valid (no conflict in row/col/box).
    func isValidPlacement(value: Int, row: Int, col: Int, board: [[Int]]) -> Bool {
        let used = SudokuBoardUtils.usedValues(row: row, col: col, in: board)
        return !used.contains(value)
    }

    /// Check if the board matches the complete solution.
    func isSolved(_ board: [[SudokuCell]], solution: [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                guard let value = board[row][col].value else { return false }
                if value != solution[row][col] { return false }
            }
        }
        return true
    }

    /// Returns positions of cells where the player's value differs from the solution.
    func findErrors(_ board: [[SudokuCell]], solution: [[Int]]) -> Set<CellPosition> {
        var errors = Set<CellPosition>()
        for row in 0..<9 {
            for col in 0..<9 {
                let cell = board[row][col]
                guard let value = cell.value, !cell.isGiven else { continue }
                if value != solution[row][col] {
                    errors.insert(CellPosition(row: row, col: col))
                }
            }
        }
        return errors
    }

    /// Returns valid candidates (1-9) for an empty cell given the current board.
    func candidates(row: Int, col: Int, board: [[Int]]) -> Set<Int> {
        SudokuBoardUtils.candidates(row: row, col: col, in: board)
    }

    /// Suggests a hint: the empty cell with the fewest candidates (easiest to deduce).
    /// Returns nil if no empty cells remain.
    func suggestHint(_ board: [[SudokuCell]], solution: [[Int]]) -> CellPosition? {
        var bestPos: CellPosition?
        var bestCount = 10
        let intBoard = SudokuBoardUtils.toIntGrid(board)

        for row in 0..<9 {
            for col in 0..<9 {
                let cell = board[row][col]
                guard cell.value == nil && !cell.isGiven else { continue }
                let count = SudokuBoardUtils.candidates(row: row, col: col, in: intBoard).count
                if count > 0 && count < bestCount {
                    bestCount = count
                    bestPos = CellPosition(row: row, col: col)
                }
            }
        }
        return bestPos
    }
}
