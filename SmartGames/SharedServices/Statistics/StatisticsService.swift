import Foundation

/// Manages per-difficulty Sudoku statistics with persistence.
/// Uses v2 keys to avoid conflict with legacy stats data.
@MainActor
final class StatisticsService: ObservableObject {
    @Published private(set) var statsByDifficulty: [String: SudokuStats] = [:]

    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
        loadAll()
    }

    // MARK: - Read

    func stats(for difficulty: SudokuDifficulty) -> SudokuStats {
        statsByDifficulty[difficulty.rawValue] ?? SudokuStats()
    }

    /// Aggregates stats across all difficulties for the "All" tab.
    func aggregateStats() -> SudokuStats {
        var aggregate = SudokuStats()
        aggregate.bestTimeSeconds = Int.max

        for difficulty in SudokuDifficulty.allCases {
            let s = stats(for: difficulty)
            aggregate.gamesPlayed += s.gamesPlayed
            aggregate.gamesWon += s.gamesWon
            aggregate.totalMistakes += s.totalMistakes
            aggregate.totalTimeSeconds += s.totalTimeSeconds
            if s.bestTimeSeconds < aggregate.bestTimeSeconds {
                aggregate.bestTimeSeconds = s.bestTimeSeconds
            }
            // Streaks are per-difficulty, show max across all
            if s.currentStreak > aggregate.currentStreak {
                aggregate.currentStreak = s.currentStreak
            }
            if s.bestStreak > aggregate.bestStreak {
                aggregate.bestStreak = s.bestStreak
            }
        }
        return aggregate
    }

    // MARK: - Write

    /// Records a completed (won) game.
    func recordWin(difficulty: SudokuDifficulty, elapsedSeconds: Int, mistakes: Int) {
        var s = stats(for: difficulty)
        s.gamesPlayed += 1
        s.gamesWon += 1
        s.totalMistakes += mistakes
        s.totalTimeSeconds += elapsedSeconds
        s.currentStreak += 1
        if s.currentStreak > s.bestStreak { s.bestStreak = s.currentStreak }
        if elapsedSeconds < s.bestTimeSeconds { s.bestTimeSeconds = elapsedSeconds }
        save(s, for: difficulty)
    }

    /// Records a failed (lost) game — increments played, resets streak.
    func recordLoss(difficulty: SudokuDifficulty) {
        var s = stats(for: difficulty)
        s.gamesPlayed += 1
        s.currentStreak = 0
        save(s, for: difficulty)
    }

    /// Resets stats. Pass nil to reset all difficulties.
    func resetStats(for difficulty: SudokuDifficulty?) {
        if let difficulty {
            let key = PersistenceService.Keys.sudokuStatsV2(difficulty: difficulty.rawValue)
            persistence.delete(key: key)
            statsByDifficulty[difficulty.rawValue] = SudokuStats()
        } else {
            for diff in SudokuDifficulty.allCases {
                let key = PersistenceService.Keys.sudokuStatsV2(difficulty: diff.rawValue)
                persistence.delete(key: key)
                statsByDifficulty[diff.rawValue] = SudokuStats()
            }
        }
    }

    // MARK: - Private

    private func loadAll() {
        for difficulty in SudokuDifficulty.allCases {
            let key = PersistenceService.Keys.sudokuStatsV2(difficulty: difficulty.rawValue)
            let loaded = persistence.load(SudokuStats.self, key: key) ?? SudokuStats()
            statsByDifficulty[difficulty.rawValue] = loaded
        }
    }

    private func save(_ stats: SudokuStats, for difficulty: SudokuDifficulty) {
        statsByDifficulty[difficulty.rawValue] = stats
        let key = PersistenceService.Keys.sudokuStatsV2(difficulty: difficulty.rawValue)
        persistence.save(stats, key: key)
    }
}
