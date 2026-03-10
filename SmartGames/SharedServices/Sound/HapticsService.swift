import UIKit

/// Haptic feedback service. Full implementation in PR-02.
final class HapticsService: ObservableObject {
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {}
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {}
    func selection() {}
}
