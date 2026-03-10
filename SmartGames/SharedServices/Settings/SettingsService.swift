import Foundation

/// User preferences and settings. Full implementation in PR-02.
final class SettingsService: ObservableObject {
    @Published var isSoundEnabled: Bool = true
    @Published var isHapticsEnabled: Bool = true
    @Published var highlightRelatedCells: Bool = true
    @Published var highlightSameNumbers: Bool = true
    @Published var showTimer: Bool = true
}
