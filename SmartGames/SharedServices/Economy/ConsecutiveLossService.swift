import Foundation

/// Tracks consecutive game losses across all game modules.
/// Triggers starter pack or timed sale offers after N losses.
@MainActor
final class ConsecutiveLossService: ObservableObject {

    @Published private(set) var count: Int = 0
    /// Set when a timed-sale should be presented; nil when no active sale.
    @Published var activeSaleExpiry: Date? = nil

    private let starterPack: StarterPackService

    init(starterPack: StarterPackService) {
        self.starterPack = starterPack
    }

    /// Call when any game reports a loss/game-over.
    func recordLoss() {
        count += 1

        // Offer starter pack on first loss (if not yet offered)
        if count >= EconomyConfig.consecutiveLossesForStarterPack {
            starterPack.triggerOffer()
        }

        // Trigger timed sale after N consecutive losses
        if count >= EconomyConfig.consecutiveLossesForSale && activeSaleExpiry == nil {
            activeSaleExpiry = Date().addingTimeInterval(EconomyConfig.timeLimitedSaleDuration)
        }
    }

    /// Call when a game is won — resets the streak.
    func recordWin() {
        count = 0
    }

    func dismissSale() {
        activeSaleExpiry = nil
    }
}
