import Foundation
import UIKit

/// Manages rewarded ad lifecycle: loading, presenting, reward delivery.
/// Uses conditional compilation for GoogleMobileAds SDK.
/// In debug/stub mode: simulates 2-second ad then grants reward.
@MainActor
final class RewardedAdCoordinator: ObservableObject {
    @Published var isAdReady: Bool = false
    private var isLoading: Bool = false

    func loadAd() async {
        guard !isLoading && !isAdReady else { return }
        isLoading = true
        // Simulate ad pre-load delay (real SDK: GADRewardedAd.load)
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        isAdReady = true
        isLoading = false
    }

    /// Present the rewarded ad. Calls completion(true) on reward grant, completion(false) on failure.
    func showAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard isAdReady else {
            completion(false)
            // Pre-load next ad
            Task { await loadAd() }
            return
        }
        isAdReady = false

        // Stub: simulate watching a 2-second ad then grant reward
        // TODO: Replace with real GADRewardedAd.present() when AdMob SDK is integrated
        simulateAdPresentation(from: viewController) { granted in
            completion(granted)
            Task { await self.loadAd() } // Pre-load next ad
        }
    }

    /// Simulates ad presentation — replace this block with real AdMob API.
    private func simulateAdPresentation(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Watch Ad",
            message: "[Test Mode] Simulated rewarded ad\n\nIn production, a real AdMob ad plays here.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "✓ Watch & Earn", style: .default) { _ in
            completion(true)
        })
        alert.addAction(UIAlertAction(title: "Skip", style: .cancel) { _ in
            completion(false)
        })
        viewController.present(alert, animated: true)
    }
}
