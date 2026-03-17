import Foundation
import Combine

// MARK: - Purchase Result

enum PurchaseResult {
    case success
    case insufficientFunds
    case alreadyOwned
}

// MARK: - ThemeService

/// Publishes the active BoardTheme, tracks unlocked themes, and handles Gold-based purchases.
/// Inject as @EnvironmentObject app-wide via AppEnvironment.
@MainActor
final class ThemeService: ObservableObject {
    /// The full color palette for the currently selected theme.
    @Published private(set) var current: BoardTheme

    /// The selected theme name — changing this updates `current` and persists.
    @Published var themeName: BoardThemeName {
        didSet {
            current = BoardTheme.theme(for: themeName)
            saveTheme()
        }
    }

    /// Themes the user has purchased. Free themes (.light, .dark) are never stored here.
    @Published private(set) var unlockedThemes: Set<BoardThemeName>

    private let persistence: PersistenceService
    private let goldService: GoldService
    /// Weak ref to DiamondService for legendary theme purchases.
    weak var diamondService: DiamondService?

    init(persistence: PersistenceService, goldService: GoldService) {
        self.persistence = persistence
        self.goldService = goldService

        // Load persisted unlocked themes
        let rawUnlocked = persistence.load([String].self, key: PersistenceService.Keys.unlockedThemes) ?? []
        let decoded = Set(rawUnlocked.compactMap { BoardThemeName(rawValue: $0) })
        self.unlockedThemes = decoded

        // Load selected theme with legacy fallback
        let saved = persistence.load(BoardThemeName.self, key: PersistenceService.Keys.appTheme)
        let candidate = saved ?? .light

        // If saved theme is paid and not in unlocked set, fallback to .light
        if !candidate.isFree && !decoded.contains(candidate) {
            self.themeName = .light
            self.current = BoardTheme.theme(for: .light)
        } else {
            self.themeName = candidate
            self.current = BoardTheme.theme(for: candidate)
        }
    }

    // MARK: - Public API

    /// Returns true if the theme is free or has been purchased.
    func isUnlocked(_ name: BoardThemeName) -> Bool {
        name.isFree || unlockedThemes.contains(name)
    }

    /// Switches to the given theme. Silently ignores if theme is locked.
    func setTheme(_ name: BoardThemeName) {
        guard isUnlocked(name) else { return }
        themeName = name
    }

    /// Attempt to purchase a theme with Gold.
    /// Returns .alreadyOwned, .insufficientFunds, or .success.
    @discardableResult
    func purchase(_ name: BoardThemeName) -> PurchaseResult {
        guard !isUnlocked(name) else { return .alreadyOwned }
        guard goldService.spend(amount: name.price) else { return .insufficientFunds }
        unlockedThemes.insert(name)
        saveUnlocked()
        return .success
    }

    /// Attempt to purchase a legendary theme with Diamonds.
    /// Returns .alreadyOwned, .insufficientFunds, or .success.
    @discardableResult
    func purchaseWithDiamonds(_ name: BoardThemeName) -> PurchaseResult {
        guard !isUnlocked(name) else { return .alreadyOwned }
        guard let cost = name.diamondPrice else { return .insufficientFunds }
        guard diamondService?.spend(amount: cost) == true else { return .insufficientFunds }
        unlockedThemes.insert(name)
        saveUnlocked()
        return .success
    }

    /// Unlock a theme directly (used by IAP grants — Starter Pack, piggy bank).
    func grantTheme(_ name: BoardThemeName) {
        guard !isUnlocked(name) else { return }
        unlockedThemes.insert(name)
        saveUnlocked()
    }

    // MARK: - Private

    private func saveTheme() {
        persistence.save(themeName, key: PersistenceService.Keys.appTheme)
    }

    private func saveUnlocked() {
        let rawValues = unlockedThemes.map { $0.rawValue }
        persistence.save(rawValues, key: PersistenceService.Keys.unlockedThemes)
    }
}
