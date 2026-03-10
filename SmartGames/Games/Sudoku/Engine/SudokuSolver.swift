import Foundation

/// Sudoku solver using backtracking with MRV (Minimum Remaining Values) heuristic.
/// Pure logic — no UI dependencies.
final class SudokuSolver {

    /// Attempts to solve the board in-place. Returns solved grid or nil if unsolvable.
    func solve(_ board: [[Int]]) -> [[Int]]? {
        var grid = board
        return backtrack(&grid) ? grid : nil
    }

    /// Returns the number of solutions (stops counting at `limit`).
    /// Use limit=2 to check uniqueness: 0=invalid, 1=unique, 2+=not unique.
    func countSolutions(_ board: [[Int]], limit: Int = 2) -> Int {
        var grid = board
        var count = 0
        countBacktrack(&grid, count: &count, limit: limit)
        return count
    }

    // MARK: - Private

    /// Finds the empty cell with fewest candidates (MRV heuristic) — reduces search space.
    private func findBestCell(_ grid: [[Int]]) -> (Int, Int)? {
        var bestPos: (Int, Int)?
        var bestCount = 10

        for row in 0..<9 {
            for col in 0..<9 {
                guard grid[row][col] == 0 else { continue }
                let count = SudokuBoardUtils.candidates(row: row, col: col, in: grid).count
                if count == 0 { return nil } // dead end — no valid number exists
                if count < bestCount {
                    bestCount = count
                    bestPos = (row, col)
                }
            }
        }
        return bestPos
    }

    private func backtrack(_ grid: inout [[Int]]) -> Bool {
        guard let (row, col) = findBestCell(grid) else {
            // No empty cells found — check fully solved
            return grid.flatMap { $0 }.allSatisfy { $0 != 0 }
        }

        for num in SudokuBoardUtils.candidates(row: row, col: col, in: grid).sorted() {
            grid[row][col] = num
            if backtrack(&grid) { return true }
            grid[row][col] = 0
        }
        return false
    }

    private func countBacktrack(_ grid: inout [[Int]], count: inout Int, limit: Int) {
        guard count < limit else { return }

        guard let (row, col) = findBestCell(grid) else {
            if grid.flatMap({ $0 }).allSatisfy({ $0 != 0 }) { count += 1 }
            return
        }

        for num in SudokuBoardUtils.candidates(row: row, col: col, in: grid) {
            grid[row][col] = num
            countBacktrack(&grid, count: &count, limit: limit)
            grid[row][col] = 0
            if count >= limit { return }
        }
    }
}
