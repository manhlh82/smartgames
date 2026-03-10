import Foundation
import UIKit

/// Manages interstitial ad lifecycle with rate limiting.
/// V1: max 1 interstitial per session, only shown at natural break points (post-win).
@MainActor
final class InterstitialAdCoordinator: ObservableObject {
    @Published var isAdReady: Bool = false
    private var showCount: Int = 0
    private var lastShowTime: Date = .distantPast

    /// Whether an interstitial can be shown right now (rate limit check).
    var canShowAd: Bool {
        isAdReady
        && showCount < AdsConfig.maxInterstitialsPerSession
        && Date().timeIntervalSince(lastShowTime) > Double(AdsConfig.interstitialCooldownSeconds)
    }

    func loadAd() async {
        guard !isAdReady else { return }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        isAdReady = true
    }

    /// Show the interstitial if all rate limit conditions are met.
    func showIfReady(from viewController: UIViewController) {
        guard canShowAd else { return }
        isAdReady = false
        showCount += 1
        lastShowTime = Date()

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
