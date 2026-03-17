import Foundation

/// Tracks Starter Pack offer and claim state.
/// The pack is offered once per install on first game loss or after 5 min session time.
/// Contents: 50 diamonds + Aurora exclusive theme unlock.
@MainActor
final class StarterPackService: ObservableObject {

    static let diamondGrant = 50
    static let exclusiveTheme: BoardThemeName = .aurora

    /// True once the pack has been shown (even if dismissed without purchase).
    @Published private(set) var hasBeenOffered: Bool = false
    /// True once the pack has been purchased and rewards granted.
    @Published private(set) var hasBeenClaimed: Bool = false
    /// Set by triggers (loss / timer) when the popup should appear.
    @Published var shouldShowOffer: Bool = false

    private let persistence: PersistenceService
    private static let offeredKey  = "app.starterPack.offered"
    private static let claimedKey  = "app.starterPack.claimed"

    init(persistence: PersistenceService) {
        self.persistence = persistence
        self.hasBeenOffered = persistence.load(Bool.self, key: Self.offeredKey) ?? false
        self.hasBeenClaimed = persistence.load(Bool.self, key: Self.claimedKey) ?? false
    }

    // MARK: - Public API

    /// Trigger the offer if it hasn't been shown yet.
    func triggerOffer() {
        guard !hasBeenOffered && !hasBeenClaimed else { return }
        hasBeenOffered = true
        persistence.save(true, key: Self.offeredKey)
        shouldShowOffer = true
    }

    /// Call after successful IAP purchase to grant rewards.
    func claimRewards(diamondService: DiamondService, themeService: ThemeService) {
        guard !hasBeenClaimed else { return }
        hasBeenClaimed = true
        persistence.save(true, key: Self.claimedKey)
        shouldShowOffer = false
        diamondService.earn(amount: Self.diamondGrant)
        themeService.grantTheme(Self.exclusiveTheme)
    }

    /// Dismiss offer without purchase (marks as offered so it won't show again).
    func dismissOffer() {
        shouldShowOffer = false
    }
}
