import Foundation

/// Pure utility functions for Sudoku board operations.
/// No state — all functions are static/pure.
enum SudokuBoardUtils {

    /// Returns all (row, col) positions in the same row.
    static func rowIndices(for row: Int) -> [(Int, Int)] {
        (0..<9).map { (row, $0) }
    }

    /// Returns all (row, col) positions in the same column.
    static func colIndices(for col: Int) -> [(Int, Int)] {
        (0..<9).map { ($0, col) }
    }

    /// Returns all (row, col) positions in the same 3x3 box.
    static func boxIndices(for row: Int, col: Int) -> [(Int, Int)] {
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        return (0..<3).flatMap { r in (0..<3).map { c in (boxRow + r, boxCol + c) } }
    }

    /// Returns all peers (same row, col, or box) — excludes the position itself.
    static func peers(for row: Int, col: Int) -> Set<CellPosition> {
        let all = rowIndices(for: row) + colIndices(for: col) + boxIndices(for: row, col: col)
        return Set(all.compactMap { (r, c) -> CellPosition? in
            guard r != row || c != col else { return nil }
            return CellPosition(row: r, col: c)
        })
    }

    /// Returns the set of values already used in the row, col, and box of the given position.
    static func usedValues(row: Int, col: Int, in board: [[Int]]) -> Set<Int> {
        let positions = rowIndices(for: row) + colIndices(for: col) + boxIndices(for: row, col: col)
        return Set(positions.compactMap { (r, c) -> Int? in
            let v = board[r][c]
            return v != 0 ? v : nil
        })
    }

    /// Returns valid candidates (1-9 not yet used in same row/col/box).
    static func candidates(row: Int, col: Int, in board: [[Int]]) -> Set<Int> {
        guard board[row][col] == 0 else { return [] }
        return Set(1...9).subtracting(usedValues(row: row, col: col, in: board))
    }

    /// Converts a 9x9 [[SudokuCell]] board to [[Int]] (0 = empty).
    static func toIntGrid(_ board: [[SudokuCell]]) -> [[Int]] {
        board.map { row in row.map { $0.value ?? 0 } }
    }
}
