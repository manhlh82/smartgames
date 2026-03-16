import SwiftUI

/// Provides level progress data for the Drop Rush lobby grid.
@MainActor
final class DropRushLobbyViewModel: ObservableObject {
    @Published private(set) var progress: DropRushProgress

    let levels: [LevelConfig] = LevelDefinitions.levels
    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
        self.progress = persistence.load(DropRushProgress.self, key: PersistenceService.Keys.dropRushProgress) ?? DropRushProgress()
    }

    func refreshProgress() {
        progress = persistence.load(DropRushProgress.self, key: PersistenceService.Keys.dropRushProgress) ?? DropRushProgress()
    }
}
