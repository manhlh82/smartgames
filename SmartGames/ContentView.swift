import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject var environment: AppEnvironment
    @EnvironmentObject var gameRegistry: GameRegistry
    @EnvironmentObject var analytics: AnalyticsService
    @EnvironmentObject var starterPack: StarterPackService
    @EnvironmentObject var dailyLogin: DailyLoginRewardService
    @EnvironmentObject var adRewardTracker: AdRewardTracker
    @EnvironmentObject var consecutiveLoss: ConsecutiveLossService

    @State private var showSkipAdsBanner = false
    @State private var showTimedSale = false

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: $router.path) {
                HubView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .gameLobby(let gameId):
                            if let module = gameRegistry.module(for: gameId) {
                                module.makeLobbyView(environment: environment)
                            }
                        case .gamePlay(let gameId, _):
                            if let module = gameRegistry.module(for: gameId) {
                                module.navigationDestination(for: route, environment: environment)
                            }
                        case .settings:
                            SettingsView()
                        }
                    }
            }
            .environmentObject(router)

            // Global overlays — ordered by priority (highest last = topmost)

            // Daily login reward popup
            if let reward = dailyLogin.pendingReward {
                DailyLoginPopupView(reward: reward) {
                    analytics.log(.dailyLoginClaimed(
                        streakDay: reward.streakDay,
                        goldAmount: reward.goldAmount,
                        diamondAmount: reward.diamondAmount
                    ))
                    dailyLogin.clearPendingReward()
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
                .onAppear { analytics.log(.popupShown(type: "daily_login")) }
            }

            // Starter pack offer popup
            if starterPack.shouldShowOffer {
                StarterPackPopupView()
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(20)
                    .onAppear {
                        analytics.log(.popupShown(type: "starter_pack"))
                        analytics.log(.starterPackShown)
                    }
            }

            // Timed sale popup (after consecutive losses)
            if showTimedSale, let expiry = consecutiveLoss.activeSaleExpiry {
                TimedSalePopupView(
                    expiresAt: expiry,
                    discountLabel: "30% OFF",
                    onShop: {
                        analytics.log(.ctaClicked(type: "timed_sale", action: "shop_now"))
                        analytics.log(.timedSalePurchased)
                        showTimedSale = false
                        consecutiveLoss.dismissSale()
                        router.navigate(to: .settings)
                    },
                    onDismiss: {
                        analytics.log(.popupDismissed(type: "timed_sale"))
                        showTimedSale = false
                        consecutiveLoss.dismissSale()
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(15)
                .onAppear {
                    analytics.log(.timedSaleShown(
                        trigger: "consecutive_losses",
                        consecutiveLosses: consecutiveLoss.count
                    ))
                }
            }

            // Skip-ads banner (non-intrusive, bottom)
            if showSkipAdsBanner {
                SkipAdsBannerView(
                    onRemoveAds: {
                        analytics.log(.ctaClicked(type: "skip_ads_banner", action: "shop_now"))
                        showSkipAdsBanner = false
                        router.navigate(to: .settings)
                    },
                    onDismiss: {
                        analytics.log(.popupDismissed(type: "skip_ads_banner"))
                        showSkipAdsBanner = false
                    }
                )
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(5)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: starterPack.shouldShowOffer)
        .animation(.easeInOut(duration: 0.25), value: dailyLogin.pendingReward == nil)
        .animation(.easeInOut(duration: 0.25), value: showSkipAdsBanner)
        .animation(.easeInOut(duration: 0.25), value: showTimedSale)
        .onReceive(NotificationCenter.default.publisher(for: .adsShowRemoveAdsBanner)) { _ in
            showSkipAdsBanner = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .gameOverOccurred)) { _ in
            consecutiveLoss.recordLoss()
            if consecutiveLoss.activeSaleExpiry != nil {
                showTimedSale = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gameWonOccurred)) { _ in
            consecutiveLoss.recordWin()
        }
        // Timer-based starter pack trigger (5 min session)
        .task {
            try? await Task.sleep(nanoseconds: UInt64(EconomyConfig.starterPackSessionTimerSeconds * 1_000_000_000))
            starterPack.triggerOffer()
        }
    }
}
