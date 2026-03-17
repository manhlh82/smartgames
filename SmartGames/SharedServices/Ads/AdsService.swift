import Foundation
import UIKit
import Combine

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the session ad-watch count reaches the skip-ads CTA threshold.
    static let adsShowSkipAdsCTA = Notification.Name("ads.showSkipAdsCTA")
    /// Posted when the session ad-watch count reaches the starter-pack offer threshold.
    static let adsShowStarterPackOffer = Notification.Name("ads.showStarterPackOffer")
    /// Posted when the daily ad-watch count reaches the remove-ads banner threshold.
    static let adsShowRemoveAdsBanner = Notification.Name("ads.showRemoveAdsBanner")
    /// Posted by any game ViewModel when the player loses.
    static let gameOverOccurred = Notification.Name("game.gameOverOccurred")
    /// Posted by any game ViewModel when the player wins or completes a level.
    static let gameWonOccurred = Notification.Name("game.gameWonOccurred")
}

/// Coordinates all ad formats (rewarded + interstitial).
/// Injects into SwiftUI as @EnvironmentObject.
@MainActor
final class AdsService: ObservableObject {
    let rewarded = RewardedAdCoordinator()
    let interstitial = InterstitialAdCoordinator()

    @Published var isRewardedAdReady: Bool = false
    /// Number of rewarded ads watched this app session (resets on cold start).
    @Published private(set) var sessionAdWatchCount: Int = 0

    private var cancellables = Set<AnyCancellable>()

    /// Weak reference to StoreService — set by AppEnvironment after init.
    weak var storeService: StoreService?
    /// Weak reference to AdRewardTracker — set by AppEnvironment after init.
    weak var adRewardTracker: AdRewardTracker?
    /// Weak reference to DiamondService for rare drop grants.
    weak var diamondService: DiamondService?

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

    /// Show a rewarded ad with an explicit context. Resolves the outcome and calls back with success/failure.
    /// - Gold-context ads respect the daily cap via AdRewardTracker.
    /// - Continue/undo ads bypass the daily cap.
    /// - All successful watches roll for a rare diamond drop (0.2%).
    func showRewardedAd(context: AdContext = .goldReward, completion: @escaping (Bool) -> Void) {
        if storeService?.hasRemovedAds == true {
            completion(true)
            return
        }
        guard let rootVC = rootViewController else {
            completion(false)
            return
        }
        Task {
            await rewarded.showAd(from: rootVC) { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.handleAdWatchSuccess(context: context)
                }
                completion(granted)
            }
        }
    }

    /// Legacy overload — maps to .goldReward context for backward compatibility.
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        showRewardedAd(context: .goldReward, completion: completion)
    }

    // MARK: - Internal: post-watch reward dispatch

    private func handleAdWatchSuccess(context: AdContext) {
        // Increment session counter and fire conversion notifications
        sessionAdWatchCount += 1
        if sessionAdWatchCount == EconomyConfig.sessionAdWatchSkipCTAThreshold {
            NotificationCenter.default.post(name: .adsShowSkipAdsCTA, object: nil)
        }
        if sessionAdWatchCount == EconomyConfig.sessionAdWatchSkipCTAThreshold {
            NotificationCenter.default.post(name: .adsShowStarterPackOffer, object: nil)
        }

        // Rare diamond drop (0.2%) — applies to all ad contexts
        if Double.random(in: 0..<1) < EconomyConfig.adDiamondDropChance {
            diamondService?.earn(amount: 1)
        }

        // Record daily gold-ad watch for cap tracking
        if context == .goldReward {
            adRewardTracker?.recordGoldAdWatch()
            // Show remove-ads banner after threshold
            let dailyCount = adRewardTracker?.todayCount ?? 0
            if dailyCount >= EconomyConfig.dailyAdWatchRemoveBannerThreshold {
                NotificationCenter.default.post(name: .adsShowRemoveAdsBanner, object: nil)
            }
        }
    }

    /// Show an interstitial ad at a natural break point (post-win).
    /// Skipped entirely when the user has purchased Remove Ads.
    func showInterstitialIfReady() {
        guard storeService?.hasRemovedAds != true else { return }
        guard let rootVC = rootViewController else { return }
        interstitial.showIfReady(from: rootVC)
    }

    /// Creates a banner coordinator configured with the given game ID and analytics service.
    /// The coordinator is owned by the game view — it lives only while the game screen is active.
    func makeBannerCoordinator(gameId: String = "sudoku", analytics: AnalyticsService? = nil) -> BannerAdCoordinator {
        let coordinator = BannerAdCoordinator(adUnitID: AdsConfig.bannerAdUnitID)
        coordinator.gameId = gameId
        coordinator.analytics = analytics
        return coordinator
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
