import Foundation
import Combine

/// User preferences persisted across launches.
final class SettingsService: ObservableObject {
    @Published var isSoundEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var isMusicEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var isHapticsEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var highlightRelatedCells: Bool {
        didSet { saveSettings() }
    }
    @Published var highlightSameNumbers: Bool {
        didSet { saveSettings() }
    }
    @Published var showTimer: Bool {
        didSet { saveSettings() }
    }

    private let persistence: PersistenceService

    init(persistence: PersistenceService = PersistenceService()) {
        self.persistence = persistence
        if let saved = persistence.load(SettingsData.self, key: PersistenceService.Keys.appSettings) {
            isSoundEnabled        = saved.isSoundEnabled
            isMusicEnabled        = saved.isMusicEnabled
            isHapticsEnabled      = saved.isHapticsEnabled
            highlightRelatedCells = saved.highlightRelatedCells
            highlightSameNumbers  = saved.highlightSameNumbers
            showTimer             = saved.showTimer
        } else {
            isSoundEnabled        = true
            isMusicEnabled        = true
            isHapticsEnabled      = true
            highlightRelatedCells = true
            highlightSameNumbers  = true
            showTimer             = true
        }
    }

    private func saveSettings() {
        let data = SettingsData(
            isSoundEnabled: isSoundEnabled,
            isMusicEnabled: isMusicEnabled,
            isHapticsEnabled: isHapticsEnabled,
            highlightRelatedCells: highlightRelatedCells,
            highlightSameNumbers: highlightSameNumbers,
            showTimer: showTimer
        )
        persistence.save(data, key: PersistenceService.Keys.appSettings)
    }
}

/// Codable mirror of SettingsService for persistence.
/// Uses decodeIfPresent with defaults for backward compatibility with older saved data.
private struct SettingsData: Codable {
    let isSoundEnabled: Bool
    let isMusicEnabled: Bool
    let isHapticsEnabled: Bool
    let highlightRelatedCells: Bool
    let highlightSameNumbers: Bool
    let showTimer: Bool

    init(isSoundEnabled: Bool, isMusicEnabled: Bool, isHapticsEnabled: Bool,
         highlightRelatedCells: Bool, highlightSameNumbers: Bool, showTimer: Bool) {
        self.isSoundEnabled        = isSoundEnabled
        self.isMusicEnabled        = isMusicEnabled
        self.isHapticsEnabled      = isHapticsEnabled
        self.highlightRelatedCells = highlightRelatedCells
        self.highlightSameNumbers  = highlightSameNumbers
        self.showTimer             = showTimer
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isSoundEnabled        = try c.decodeIfPresent(Bool.self, forKey: .isSoundEnabled)        ?? true
        isMusicEnabled        = try c.decodeIfPresent(Bool.self, forKey: .isMusicEnabled)        ?? true
        isHapticsEnabled      = try c.decodeIfPresent(Bool.self, forKey: .isHapticsEnabled)      ?? true
        highlightRelatedCells = try c.decodeIfPresent(Bool.self, forKey: .highlightRelatedCells) ?? true
        highlightSameNumbers  = try c.decodeIfPresent(Bool.self, forKey: .highlightSameNumbers)  ?? true
        showTimer             = try c.decodeIfPresent(Bool.self, forKey: .showTimer)             ?? true
    }
}
