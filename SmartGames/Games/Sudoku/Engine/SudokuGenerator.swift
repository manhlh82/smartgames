import Foundation

/// Generates valid Sudoku puzzles using backtracking with random fill order.
/// Each call produces a different puzzle. All generated puzzles have exactly one solution.
/// Pass a `SeededRandomNumberGenerator` via `generate(difficulty:using:)` for deterministic output.
final class SudokuGenerator {
    private let solver = SudokuSolver()

    /// Generate a valid puzzle using the system RNG (non-deterministic).
    /// - Note: May take 50-500ms depending on difficulty. Call from a background Task.
    func generate(difficulty: SudokuDifficulty) -> SudokuPuzzle {
        var rng = SystemRandomNumberGenerator()
        return generate(difficulty: difficulty, using: &rng)
    }

    /// Generate a deterministic puzzle by injecting a custom RNG (e.g. `SeededRandomNumberGenerator`).
    /// Same RNG seed always produces the same puzzle.
    func generate<RNG: RandomNumberGenerator>(difficulty: SudokuDifficulty, using rng: inout RNG) -> SudokuPuzzle {
        let solution = generateCompleteSolution(using: &rng)
        let givens = removeClues(from: solution, targetGivens: difficulty.targetGivens, using: &rng)
        return SudokuPuzzle(
            difficulty: difficulty,
            givens: givens,
            solution: solution
        )
    }

    // MARK: - Private

    /// Fill a 9x9 grid with a valid complete Sudoku solution via random backtracking.
    private func generateCompleteSolution<RNG: RandomNumberGenerator>(using rng: inout RNG) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillGrid(&grid, using: &rng)
        return grid
    }

    private func fillGrid<RNG: RandomNumberGenerator>(_ grid: inout [[Int]], using rng: inout RNG) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                guard grid[row][col] == 0 else { continue }
                // Shuffle candidates with the injected RNG for deterministic or random output
                let candidates = Array(SudokuBoardUtils.candidates(row: row, col: col, in: grid)).shuffled(using: &rng)
                for num in candidates {
                    grid[row][col] = num
                    if fillGrid(&grid, using: &rng) { return true }
                    grid[row][col] = 0
                }
                return false // no valid number for this cell — backtrack
            }
        }
        return true // all cells filled successfully
    }

    /// Remove clues one by one while preserving unique solvability.
    /// Stops when the target given count is reached.
    private func removeClues<RNG: RandomNumberGenerator>(
        from solution: [[Int]], targetGivens: Int, using rng: inout RNG
    ) -> [[Int]] {
        var givens = solution
        let positions = (0..<81).map { ($0 / 9, $0 % 9) }.shuffled(using: &rng)
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
