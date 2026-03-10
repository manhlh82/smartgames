import Foundation

/// Manages the pool of available Sudoku puzzles.
/// Loads bundled puzzles from JSON, falls back to on-device generation when exhausted.
final class PuzzleBank {
    private let generator = SudokuGenerator()
    private let persistence: PersistenceService
    private var loadedPuzzles: [SudokuDifficulty: [SudokuPuzzle]] = [:]

    init(persistence: PersistenceService) {
        self.persistence = persistence
        loadBundledPuzzles()
    }

    /// Get a puzzle for the given difficulty.
    /// Returns an unplayed bundled puzzle if available, otherwise generates one on-device.
    func getPuzzle(for difficulty: SudokuDifficulty) async -> SudokuPuzzle {
        let playedIDs = loadPlayedIDs()
        let available = (loadedPuzzles[difficulty] ?? []).filter { !playedIDs.contains($0.id) }

        if let puzzle = available.randomElement() {
            markAsPlayed(puzzleID: puzzle.id)
            return puzzle
        }

        // All bundled puzzles played — generate a fresh one off the main thread
        return await Task.detached(priority: .userInitiated) {
            self.generator.generate(difficulty: difficulty)
        }.value
    }

    // MARK: - Private

    private func loadBundledPuzzles() {
        guard let url = Bundle.main.url(forResource: "puzzles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bank = try? JSONDecoder().decode(PuzzleBankJSON.self, from: data) else {
            return
        }
        loadedPuzzles[.easy]   = bank.easy.map   { $0.toPuzzle(difficulty: .easy) }
        loadedPuzzles[.medium] = bank.medium.map { $0.toPuzzle(difficulty: .medium) }
        loadedPuzzles[.hard]   = bank.hard.map   { $0.toPuzzle(difficulty: .hard) }
        loadedPuzzles[.expert] = bank.expert.map { $0.toPuzzle(difficulty: .expert) }
    }

    private func loadPlayedIDs() -> Set<String> {
        persistence.load(Set<String>.self, key: PersistenceService.Keys.sudokuPlayedPuzzleIDs) ?? []
    }

    private func markAsPlayed(puzzleID: String) {
        var played = loadPlayedIDs()
        played.insert(puzzleID)
        // Reset when all bundled puzzles have been played so they can be replayed
        let total = loadedPuzzles.values.flatMap { $0 }.count
        if total > 0 && played.count >= total { played = [] }
        persistence.save(played, key: PersistenceService.Keys.sudokuPlayedPuzzleIDs)
    }
}

// MARK: - JSON decoding models (file-private)

private struct PuzzleBankJSON: Codable {
    let easy: [PuzzleJSON]
    let medium: [PuzzleJSON]
    let hard: [PuzzleJSON]
    let expert: [PuzzleJSON]
}

private struct PuzzleJSON: Codable {
    let id: String
    let givens: [[Int]]
    let solution: [[Int]]

    func toPuzzle(difficulty: SudokuDifficulty) -> SudokuPuzzle {
        SudokuPuzzle(id: id, difficulty: difficulty, givens: givens, solution: solution)
    }
}
