import Foundation

/// Manages the daily Stack 2048 challenge — deterministic seed-based initial tiles,
/// streak tracking, completion state persistence, gold rewards, and GameCenter submission.
@MainActor
final class Stack2048DailyChallengeService: ObservableObject {
    @Published var todayState: Stack2048DailyChallengeState
    @Published var streak: Stack2048DailyStreakData

    private let persistence: PersistenceService
    private let gold: GoldService
    private let gameCenter: GameCenterService

    // MARK: - Init

    init(persistence: PersistenceService, gold: GoldService, gameCenter: GameCenterService) {
        self.persistence = persistence
        self.gold = gold
        self.gameCenter = gameCenter

        let today = DailyChallengeService.utcDateString()
        self.todayState = persistence.load(Stack2048DailyChallengeState.self,
                                           key: PersistenceService.Keys.stack2048DailyState)
                          ?? Stack2048DailyChallengeState(dateString: today, isCompleted: false)
        self.streak = persistence.load(Stack2048DailyStreakData.self,
                                       key: PersistenceService.Keys.stack2048DailyStreak)
                      ?? Stack2048DailyStreakData()

        // Reset state if a new day has started
        if todayState.dateString != today {
            todayState = Stack2048DailyChallengeState(dateString: today, isCompleted: false)
            persistence.save(todayState, key: PersistenceService.Keys.stack2048DailyState)
        }
    }

    // MARK: - Initial Tiles

    /// Returns seed-based pre-placed tiles for today's board: 2–3 tiles with values 2 or 4.
    /// Format: (col, row, value) — col 0-based, row 0 = bottom of column.
    func todayInitialTiles() -> [(col: Int, row: Int, value: Int)] {
        let today = DailyChallengeService.utcDateString()
        let seed = SeededRandomNumberGenerator.seed(from: today)
        var rng = SeededRandomNumberGenerator(seed: seed)

        let tileCount = 2 + Int(rng.next() % 2)   // 2 or 3 tiles
        let colCount = Stack2048GameState.columnCount
        var usedCols: Set<Int> = []
        var tiles: [(col: Int, row: Int, value: Int)] = []

        for _ in 0..<tileCount {
            var col = Int(rng.next() % UInt64(colCount))
            // Avoid duplicate columns
            var attempts = 0
            while usedCols.contains(col) && attempts < colCount {
                col = (col + 1) % colCount
                attempts += 1
            }
            usedCols.insert(col)
            let value = (rng.next() % 2 == 0) ? 2 : 4
            tiles.append((col: col, row: 0, value: value))
        }
        return tiles
    }

    // MARK: - Completion

    func isCompletedToday() -> Bool { todayState.isCompleted }

    /// Call when player reaches the 256 tile (or score threshold) in today's daily challenge.
    func markCompleted(score: Int) {
        guard !todayState.isCompleted else { return }
        let today = DailyChallengeService.utcDateString()
        todayState.isCompleted = true
        todayState.score = score
        persistence.save(todayState, key: PersistenceService.Keys.stack2048DailyState)

        // Grant gold reward (no star system for Stack 2048 daily)
        gold.earn(amount: EconomyConfig.dailyChallengeCompleteGold)

        // Submit to GameCenter leaderboard
        gameCenter.submitScore(score, leaderboardID: GameCenterService.DailyLeaderboardID.stack2048)

        updateStreak(today: today)
    }

    // MARK: - Streak

    private func updateStreak(today: String) {
        var updated = streak
        if let last = updated.lastCompletedDate {
            if last == yesterday() {
                updated.currentStreak += 1
            } else if last == today {
                // Already counted — no-op
            } else {
                updated.currentStreak = 1
            }
        } else {
            updated.currentStreak = 1
        }
        updated.bestStreak = max(updated.bestStreak, updated.currentStreak)
        updated.lastCompletedDate = today
        streak = updated
        persistence.save(streak, key: PersistenceService.Keys.stack2048DailyStreak)
    }

    private func yesterday() -> String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return DailyChallengeService.utcDateString(from: yesterday)
    }
}
