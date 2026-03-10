import UIKit

/// Provides haptic feedback. Respects SettingsService.isHapticsEnabled.
final class HapticsService: ObservableObject {
    private var settingsService: SettingsService?

    /// Inject settings after init.
    func configure(settings: SettingsService) {
        self.settingsService = settings
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard settingsService?.isHapticsEnabled ?? true else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard settingsService?.isHapticsEnabled ?? true else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    func selection() {
        guard settingsService?.isHapticsEnabled ?? true else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
