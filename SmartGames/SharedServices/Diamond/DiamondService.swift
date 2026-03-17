import Foundation

// MARK: - Diamond Reward / Spend Constants

/// Static amounts for all diamond-related economy events.
enum DiamondReward {
    // Free earn rates
    /// Probability of dropping 1 diamond on a big merge (tile value ≥ 256).
    static let bigMergeDropChance: Double = 0.005   // 0.5%
    /// Probability of dropping 1 diamond after watching a rewarded ad.
    static let adWatchDropChance: Double = 0.002    // 0.2%
    // Event rewards
    static let weeklyChallengMin = 1
    static let weeklyChallengMax = 3
    static let dailyLoginDay7Amount = 1
    // Spend costs
    static let continueFullReviveCost = 2
    static let undoCost = 1
}

// MARK: - DiamondService

/// Manages the shared premium Diamond balance.
/// Earned via rare drops and events; spent on continues, undos, and premium cosmetics.
/// Inject as @EnvironmentObject via AppEnvironment.
@MainActor
final class DiamondService: ObservableObject {
    /// Current Diamond balance — never negative, capped at Int.max / 2.
    @Published private(set) var balance: Int = 0

    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
        self.balance = persistence.load(Int.self, key: PersistenceService.Keys.diamondBalance) ?? 0
    }

    // MARK: - Public API

    /// Add diamonds to balance. Overflow-safe (clamps to Int.max / 2).
    func earn(amount: Int) {
        guard amount > 0 else { return }
        let cap = Int.max / 2
        let (result, overflow) = balance.addingReportingOverflow(amount)
        balance = overflow ? cap : min(result, cap)
        save()
    }

    /// Attempt to spend diamonds. Returns false if insufficient balance (balance unchanged).
    @discardableResult
    func spend(amount: Int) -> Bool {
        guard amount > 0 else { return true }
        guard balance >= amount else { return false }
        balance -= amount
        save()
        return true
    }

    // MARK: - Private

    private func save() {
        persistence.save(balance, key: PersistenceService.Keys.diamondBalance)
    }
}
