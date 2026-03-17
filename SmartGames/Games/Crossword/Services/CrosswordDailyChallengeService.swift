import Foundation

@MainActor
final class CrosswordDailyChallengeService: ObservableObject {
    @Published var todayState: CrosswordDailyChallengeState
    @Published var streak: CrosswordDailyStreakData

    private let persistence: PersistenceService
    private let gold: GoldService
    private let gameCenter: GameCenterService

    init(persistence: PersistenceService, gold: GoldService, gameCenter: GameCenterService) {
        self.persistence = persistence
        self.gold = gold
        self.gameCenter = gameCenter

        let today = DailyChallengeService.utcDateString()
        self.todayState = persistence.load(CrosswordDailyChallengeState.self,
                                           key: PersistenceService.Keys.crosswordDailyState)
                          ?? CrosswordDailyChallengeState(dateString: today, isCompleted: false)
        self.streak = persistence.load(CrosswordDailyStreakData.self,
                                       key: PersistenceService.Keys.crosswordDailyStreak)
                      ?? CrosswordDailyStreakData()

        // Reset if a new day has started
        if todayState.dateString != today {
            todayState = CrosswordDailyChallengeState(dateString: today, isCompleted: false)
            persistence.save(todayState, key: PersistenceService.Keys.crosswordDailyState)
        }
    }

    /// Returns today's deterministic puzzle — seeded by UTC date string.
    func todayPuzzle(bank: CrosswordPuzzleBank) -> CrosswordPuzzle {
        let today = DailyChallengeService.utcDateString()
        let difficulty: CrosswordDifficulty = isWeekend() ? .mini : .standard
        let pool = bank.allPuzzles(for: difficulty)
        // Fallback to mini if standard pool is empty
        let finalPool = pool.isEmpty ? bank.allPuzzles(for: .mini) : pool
        guard !finalPool.isEmpty else {
            // Last-resort: return first puzzle of any difficulty
            return bank.allPuzzles(for: .mini).first
                ?? CrosswordPuzzle(id: "fallback", difficulty: .mini, size: 5, grid: [], clues: [])
        }
        let seed = SeededRandomNumberGenerator.seed(from: today)
        var rng = SeededRandomNumberGenerator(seed: seed)
        let index = Int(rng.next() % UInt64(finalPool.count))
        return finalPool[index]
    }

    func todayDifficultyLabel() -> String {
        isWeekend() ? "Mini (5×5)" : "Standard (9×9)"
    }

    func isCompletedToday() -> Bool { todayState.isCompleted }

    func markCompleted(timeSeconds: Int, hintsUsed: Int, stars: Int) {
        guard !todayState.isCompleted else { return }
        let today = DailyChallengeService.utcDateString()
        todayState.isCompleted = true
        todayState.timeSeconds = timeSeconds
        todayState.hintsUsed = hintsUsed
        todayState.stars = stars
        persistence.save(todayState, key: PersistenceService.Keys.crosswordDailyState)

        // Grant gold reward
        var goldAmount = EconomyConfig.dailyChallengeCompleteGold
        if stars >= 3 { goldAmount += EconomyConfig.dailyChallengeThreeStarBonus }
        gold.earn(amount: goldAmount)

        // Submit score to Game Center (faster = higher score)
        let score = max(0, 3600 - timeSeconds)
        gameCenter.submitScore(score, leaderboardID: GameCenterService.DailyLeaderboardID.crossword)

        updateStreak(today: today)
    }

    // MARK: - Private

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
        persistence.save(streak, key: PersistenceService.Keys.crosswordDailyStreak)
    }

    private func yesterday() -> String {
        let date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return DailyChallengeService.utcDateString(from: date)
    }

    private func isWeekend() -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let weekday = cal.component(.weekday, from: Date())
        return weekday == 1 || weekday == 7  // Sunday=1, Saturday=7
    }
}
