import Foundation
import UIKit
import Combine

/// Coordinates all ad formats (rewarded + interstitial).
/// Injects into SwiftUI as @EnvironmentObject.
@MainActor
final class AdsService: ObservableObject {
    let rewarded = RewardedAdCoordinator()
    let interstitial = InterstitialAdCoordinator()

    @Published var isRewardedAdReady: Bool = false
    private var cancellables = Set<AnyCancellable>()

    /// Weak reference to StoreService — set by AppEnvironment after init.
    weak var storeService: StoreService?

    init() {
        // Propagate rewarded ready state
        rewarded.$isAdReady
            .receive(on: RunLoop.main)
            .assign(to: \.isRewardedAdReady, on: self)
            .store(in: &cancellables)

        // Pre-load ads on init
        Task {
            await rewarded.loadAd()
            await interstitial.loadAd()
        }
    }

    /// Show a rewarded ad. Calls completion(true) if reward was earned, (false) otherwise.
    /// If the user has purchased Remove Ads, the reward is granted immediately without showing an ad.
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        if storeService?.hasRemovedAds == true {
            completion(true)
            return
        }
        guard let rootVC = rootViewController else {
            completion(false)
            return
        }
        Task {
            await rewarded.showAd(from: rootVC, completion: completion)
        }
    }

    /// Show an interstitial ad at a natural break point (post-win).
    /// Skipped entirely when the user has purchased Remove Ads.
    func showInterstitialIfReady() {
        guard storeService?.hasRemovedAds != true else { return }
        guard let rootVC = rootViewController else { return }
        interstitial.showIfReady(from: rootVC)
    }

    /// Creates a banner coordinator configured with the given ad unit ID.
    /// The coordinator is owned by the game view — it lives only while the game screen is active.
    func makeBannerCoordinator() -> BannerAdCoordinator {
        BannerAdCoordinator(adUnitID: AdsConfig.bannerAdUnitID)
    }

    // MARK: - Private

    private var rootViewController: UIViewController? {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
