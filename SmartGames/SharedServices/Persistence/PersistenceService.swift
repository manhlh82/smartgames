import Foundation

/// Handles saving and loading of Codable game state using UserDefaults + JSON encoding.
/// All game progress, stats, and settings are stored here.
final class PersistenceService: ObservableObject {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Save any Codable value under the given key.
    func save<T: Codable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    /// Load and decode a Codable value for the given key. Returns nil if missing or decode fails.
    func load<T: Codable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    /// Remove a saved value.
    func delete(key: String) {
        defaults.removeObject(forKey: key)
    }

    /// Check if a key exists.
    func exists(key: String) -> Bool {
        defaults.object(forKey: key) != nil
    }
}

/// Keys used throughout the app — centralised to prevent typos.
extension PersistenceService {
    enum Keys {
        static let sudokuActiveGame = "sudoku.activeGame"
        static let sudokuHintsRemaining = "sudoku.hints.remaining"
        static let sudokuPlayedPuzzleIDs = "sudoku.playedPuzzleIDs"
        static let sudokuPendingPuzzle = "sudoku.pendingPuzzle"
        static func sudokuStats(difficulty: String) -> String { "sudoku.stats.\(difficulty)" }
        static func sudokuStatsV2(difficulty: String) -> String { "sudoku.stats.v2.\(difficulty)" }
        static let appSettings = "app.settings"
        static let appTheme = "app.theme"
        static let sudokuDailyState = "sudoku.daily.state"
        static let sudokuDailyStreak = "sudoku.daily.streak"
        /// Set to true when the pending puzzle is the daily challenge.
        /// Cleared after the game view consumes it.
        static let sudokuPendingIsDailyChallenge = "sudoku.pending.isDailyChallenge"
        /// BCP-47 language code override, e.g. "vi", "ja". nil = follow system locale.
        static let appLanguageCode = "app.languageCode"
        // MARK: - Drop Rush
        static let dropRushProgress = "dropRush.progress"
        static let dropRushActiveGame = "dropRush.activeGame"
        // MARK: - Gold
        static let goldBalance = "app.gold.balance"
        // MARK: - Themes
        static let unlockedThemes = "app.themes.unlocked"
    }
}
