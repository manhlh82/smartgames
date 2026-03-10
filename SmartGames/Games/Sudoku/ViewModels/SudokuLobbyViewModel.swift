import Foundation

/// Manages state for the Sudoku lobby — saved game detection and puzzle fetching.
@MainActor
final class SudokuLobbyViewModel: ObservableObject {
    @Published var hasSavedGame: Bool = false
    @Published var savedGameDifficulty: SudokuDifficulty?

    private let persistence: PersistenceService
    private let puzzleBank: PuzzleBank

    init(persistence: PersistenceService) {
        self.persistence = persistence
        self.puzzleBank = PuzzleBank(persistence: persistence)
        checkForSavedGame()
    }

    func getPuzzle(for difficulty: SudokuDifficulty) async -> SudokuPuzzle {
        await puzzleBank.getPuzzle(for: difficulty)
    }

    func loadSavedGame() -> SudokuGameState? {
        persistence.load(SudokuGameState.self, key: PersistenceService.Keys.sudokuActiveGame)
    }

    func clearSavedGame() {
        persistence.delete(key: PersistenceService.Keys.sudokuActiveGame)
        hasSavedGame = false
        savedGameDifficulty = nil
    }

    private func checkForSavedGame() {
        if let state = persistence.load(SudokuGameState.self,
                                        key: PersistenceService.Keys.sudokuActiveGame) {
            hasSavedGame = true
            savedGameDifficulty = state.puzzle.difficulty
        }
    }
}
