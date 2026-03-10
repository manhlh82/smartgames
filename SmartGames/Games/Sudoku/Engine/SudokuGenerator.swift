import Foundation

/// Generates valid Sudoku puzzles using backtracking with random fill order.
/// Each call produces a different puzzle. All generated puzzles have exactly one solution.
final class SudokuGenerator {
    private let solver = SudokuSolver()

    /// Generate a valid puzzle for the given difficulty.
    /// - Note: May take 50-500ms depending on difficulty. Call from a background Task.
    func generate(difficulty: SudokuDifficulty) -> SudokuPuzzle {
        let solution = generateCompleteSolution()
        let givens = removeClues(from: solution, targetGivens: difficulty.targetGivens)
        return SudokuPuzzle(
            difficulty: difficulty,
            givens: givens,
            solution: solution
        )
    }

    // MARK: - Private

    /// Fill a 9x9 grid with a valid complete Sudoku solution via random backtracking.
    private func generateCompleteSolution() -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillGrid(&grid)
        return grid
    }

    private func fillGrid(_ grid: inout [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                guard grid[row][col] == 0 else { continue }
                // Shuffle candidates to ensure different puzzles each run
                let candidates = Array(SudokuBoardUtils.candidates(row: row, col: col, in: grid)).shuffled()
                for num in candidates {
                    grid[row][col] = num
                    if fillGrid(&grid) { return true }
                    grid[row][col] = 0
                }
                return false // no valid number for this cell — backtrack
            }
        }
        return true // all cells filled successfully
    }

    /// Remove clues one by one while preserving unique solvability.
    /// Stops when the target given count is reached.
    private func removeClues(from solution: [[Int]], targetGivens: Int) -> [[Int]] {
        var givens = solution
        let positions = (0..<81).map { ($0 / 9, $0 % 9) }.shuffled()
        var givenCount = 81

        for (row, col) in positions {
            guard givenCount > targetGivens else { break }
            let backup = givens[row][col]
            givens[row][col] = 0
            givenCount -= 1

            // Restore cell if removing it breaks unique solvability
            if solver.countSolutions(givens, limit: 2) != 1 {
                givens[row][col] = backup
                givenCount += 1
            }
        }
        return givens
    }
}
