import Foundation
import Combine

/// User preferences persisted across launches.
final class SettingsService: ObservableObject {
    @Published var isSoundEnabled: Bool {
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
        // Load saved settings or use defaults
        if let saved = persistence.load(SettingsData.self, key: PersistenceService.Keys.appSettings) {
            isSoundEnabled = saved.isSoundEnabled
            isHapticsEnabled = saved.isHapticsEnabled
            highlightRelatedCells = saved.highlightRelatedCells
            highlightSameNumbers = saved.highlightSameNumbers
            showTimer = saved.showTimer
        } else {
            isSoundEnabled = true
            isHapticsEnabled = true
            highlightRelatedCells = true
            highlightSameNumbers = true
            showTimer = true
        }
    }

    private func saveSettings() {
        let data = SettingsData(
            isSoundEnabled: isSoundEnabled,
            isHapticsEnabled: isHapticsEnabled,
            highlightRelatedCells: highlightRelatedCells,
            highlightSameNumbers: highlightSameNumbers,
            showTimer: showTimer
        )
        persistence.save(data, key: PersistenceService.Keys.appSettings)
    }
}

/// Codable mirror of SettingsService for persistence.
private struct SettingsData: Codable {
    let isSoundEnabled: Bool
    let isHapticsEnabled: Bool
    let highlightRelatedCells: Bool
    let highlightSameNumbers: Bool
    let showTimer: Bool
}
