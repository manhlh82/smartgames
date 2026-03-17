import Foundation

/// Accumulates fractional diamonds during play; players pay to unlock and collect the savings.
/// Increments: +0.1 per game completed, +0.05 per rewarded ad watched.
/// Unlock triggered when fractionalDiamonds >= piggyBankCapacity (10.0).
@MainActor
final class PiggyBankService: ObservableObject {

    /// Current fractional diamond balance (0.0 … piggyBankCapacity+).
    @Published private(set) var fractionalDiamonds: Double = 0.0
    /// Set to true when 80%+ full — consumers observe to show a nudge toast.
    @Published var nudgeFired: Bool = false

    static let piggyBankCapacity: Double = 10.0
    static let gameCompletedIncrement: Double = 0.1
    static let adWatchedIncrement: Double = 0.05

    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
        self.fractionalDiamonds = persistence.load(Double.self, key: PersistenceService.Keys.piggyBankFractional) ?? 0.0
    }

    // MARK: - Public API

    var fillPercent: Double {
        min(fractionalDiamonds / Self.piggyBankCapacity, 1.0)
    }

    var isFull: Bool { fractionalDiamonds >= Self.piggyBankCapacity }

    var diamondsAvailable: Int { Int(fractionalDiamonds) }

    /// Call when a game session completes.
    func recordGameCompleted() {
        add(Self.gameCompletedIncrement)
    }

    /// Call when a rewarded ad is successfully watched.
    func recordAdWatched() {
        add(Self.adWatchedIncrement)
    }

    /// Collect accumulated diamonds (consumes fractional balance, grants whole diamonds to DiamondService).
    /// Returns the number of diamonds granted. Call after IAP unlock succeeds.
    @discardableResult
    func collect(into diamondService: DiamondService) -> Int {
        let amount = diamondsAvailable
        guard amount > 0 else { return 0 }
        fractionalDiamonds -= Double(amount)
        if fractionalDiamonds < 0 { fractionalDiamonds = 0 }
        save()
        diamondService.earn(amount: amount)
        return amount
    }

    // MARK: - Private

    private func add(_ amount: Double) {
        fractionalDiamonds += amount
        save()
        // Fire nudge once when crossing 80% threshold
        if fillPercent >= EconomyConfig.piggyBankNudgeThreshold && !nudgeFired {
            nudgeFired = true
        }
    }

    private func save() {
        persistence.save(fractionalDiamonds, key: PersistenceService.Keys.piggyBankFractional)
    }
}
