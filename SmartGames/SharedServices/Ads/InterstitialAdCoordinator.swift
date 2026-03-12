import Foundation
import UIKit

/// Manages interstitial ad lifecycle.
/// Shows at natural break points (post-win), frequency controlled by MonetizationConfig.
@MainActor
final class InterstitialAdCoordinator: ObservableObject {
    @Published var isAdReady: Bool = false
    private var completedLevelCount: Int = 0
    private var interstitialFrequency: Int = 1

    /// Configure frequency from MonetizationConfig. Call once when game module loads.
    func configure(frequency: Int) {
        self.interstitialFrequency = max(1, frequency)
    }

    /// Call after every level completion. Returns true if interstitial should be shown.
    @discardableResult
    func shouldShowAfterLevelComplete() -> Bool {
        completedLevelCount += 1
        return isAdReady && (completedLevelCount % interstitialFrequency == 0)
    }

    /// Reset level counter (e.g., on new session or game module change).
    func resetLevelCounter() {
        completedLevelCount = 0
    }

    func loadAd() async {
        guard !isAdReady else { return }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        isAdReady = true
    }

    /// Show the interstitial if an ad is ready.
    func showIfReady(from viewController: UIViewController) {
        guard isAdReady else { return }
        isAdReady = false

        // Stub: simulate interstitial
        // TODO: Replace with GADInterstitialAd.present() when SDK integrated
        let alert = UIAlertController(
            title: "Ad",
            message: "[Test Mode] Interstitial ad placeholder",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Continue", style: .default))
        viewController.present(alert, animated: true)
        Task { await loadAd() }
    }
}
