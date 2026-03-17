import Foundation

// MARK: - Gold Reward Constants

/// Static reward amounts for all game events that grant Gold.
enum GoldReward {
    static let sudokuComplete = 15
    static let sudokuThreeStarBonus = 10
    static let dropRushComplete = 10
    static let dropRushThreeStarBonus = 10
    static let stack2048GameOver = 10
    static let stack2048HighScoreBonus = 15
    static let stack2048Win = 50
}

// MARK: - GoldService

/// Manages the shared in-game Gold balance. Earned by completing levels, spent on themes.
/// Inject as @EnvironmentObject via AppEnvironment.
@MainActor
final class GoldService: ObservableObject {
    /// Current Gold balance — never negative, capped at Int.max / 2.
    @Published private(set) var balance: Int = 0

    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
        // Migration: read from old key if new key absent
        if let existing = persistence.load(Int.self, key: PersistenceService.Keys.goldBalance) {
            self.balance = existing
        } else if let legacy = persistence.load(Int.self, key: "app.currency.balance") {
            self.balance = legacy
            persistence.save(legacy, key: PersistenceService.Keys.goldBalance)
            persistence.delete(key: "app.currency.balance")
        } else {
            self.balance = 0
        }
    }

    // MARK: - Public API

    /// Add Gold to balance. Overflow-safe (clamps to Int.max / 2).
    func earn(amount: Int) {
        guard amount > 0 else { return }
        let cap = Int.max / 2
        let (result, overflow) = balance.addingReportingOverflow(amount)
        balance = overflow ? cap : min(result, cap)
        save()
    }

    /// Attempt to spend Gold. Returns false if insufficient balance (balance unchanged).
    func spend(amount: Int) -> Bool {
        guard amount > 0 else { return true }
        guard balance >= amount else { return false }
        balance -= amount
        save()
        return true
    }

    // MARK: - Private

    private func save() {
        persistence.save(balance, key: PersistenceService.Keys.goldBalance)
    }
}
