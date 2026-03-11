import Foundation
import Combine

// MARK: - ThemeService

/// Publishes the active BoardTheme and persists the user's choice.
/// Inject as @EnvironmentObject in views that need theme colors.
@MainActor
final class ThemeService: ObservableObject {
    /// The full color palette for the currently selected theme.
    @Published private(set) var current: BoardTheme

    /// The selected theme name — changing this updates `current` and persists.
    @Published var themeName: BoardThemeName {
        didSet {
            current = BoardTheme.theme(for: themeName)
            save()
        }
    }

    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
        // Load persisted theme name, default to .classic
        let saved = persistence.load(BoardThemeName.self, key: PersistenceService.Keys.appTheme)
        let name = saved ?? .classic
        self.themeName = name
        self.current = BoardTheme.theme(for: name)
    }

    // MARK: - Public API

    /// Switches to the given theme name, updating palette and persisting the choice.
    func setTheme(_ name: BoardThemeName) {
        themeName = name
    }

    // MARK: - Private

    private func save() {
        persistence.save(themeName, key: PersistenceService.Keys.appTheme)
    }
}
