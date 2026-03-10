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
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard let rootVC = rootViewController else {
            completion(false)
            return
        }
        Task {
            await rewarded.showAd(from: rootVC, completion: completion)
        }
    }

    /// Show an interstitial ad at a natural break point (post-win).
    /// Respects rate limits — safe to call and will no-op if not appropriate.
    func showInterstitialIfReady() {
        guard let rootVC = rootViewController else { return }
        interstitial.showIfReady(from: rootVC)
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
