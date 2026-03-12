import Foundation
import UIKit

/// Manages a single banner ad lifecycle (load, success, failure).
/// Uses stub pattern matching RewardedAdCoordinator — no real GAD types required for simulator.
@MainActor
final class BannerAdCoordinator: NSObject, ObservableObject {
    @Published var isBannerLoaded: Bool = false
    @Published var bannerHeight: CGFloat = 0

    private let adUnitID: String

    init(adUnitID: String = AdsConfig.bannerAdUnitID) {
        self.adUnitID = adUnitID
        super.init()
    }

    /// Load the banner. In production this would create and load a GADBannerView.
    /// Stub: simulates a successful load after a short delay.
    func loadBanner() {
        // Stub: simulate banner load delay then mark as loaded
        // TODO: Replace with real GADBannerView initialization when AdMob SDK is integrated
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                self.didReceiveAd(height: 50) // Standard banner height
            }
        }
    }

    // MARK: - Delegate callbacks (called by GADBannerViewDelegate in production)

    func didReceiveAd(height: CGFloat = 50) {
        isBannerLoaded = true
        bannerHeight = height
    }

    func didFailToReceiveAd() {
        isBannerLoaded = false
        bannerHeight = 0
    }
}
