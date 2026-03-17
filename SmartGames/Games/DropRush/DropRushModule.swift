import SwiftUI

/// Drop Rush game module — conforms to GameModule protocol.
/// Registers with AppEnvironment and provides lobby + gameplay navigation.
@MainActor
final class DropRushModule: GameModule {
    let id = "dropRush"
    let displayName = "Drop Rush"
    let iconName = "arrow.down.circle.fill"
    let isAvailable = true

    var audioConfig: (any AudioConfig)? { DropRushAudioConfig() }

    /// Drop Rush monetization: banner + interstitial every 2 levels.
    /// No hints (hint system is Sudoku-specific).
    /// Rewarded continue (extra life) is wired directly in Phase 07 ViewModel.
    var monetizationConfig: MonetizationConfig {
        MonetizationConfig(
            bannerEnabled: true,
            interstitialEnabled: true,
            interstitialFrequency: 2,
            rewardedHintsEnabled: false,
            rewardedHintAmount: 0,
            levelCompleteHintReward: 0,
            maxHintCap: 0,
            mistakeResetEnabled: false,
            mistakeResetUsesPerLevel: 0
        )
    }

    init(persistence: PersistenceService) {}

    func makeLobbyView(environment: AppEnvironment) -> AnyView {
        AnyView(DropRushLobbyView(
            persistence: environment.persistence,
            ads: environment.ads,
            analytics: environment.analytics
        ))
    }

    func navigationDestination(for route: AppRoute, environment: AppEnvironment) -> AnyView? {
        guard case .gamePlay(let gameId, let context) = route, gameId == id else { return nil }

        // Daily challenge info screen
        if context == "daily" {
            return AnyView(DropRushDailyChallengeView(service: environment.dropRushDailyChallenge))
        }

        // Level game
        guard context.hasPrefix("level-"), let levelNum = Int(context.dropFirst(6)) else { return nil }
        return AnyView(DropRushGameView(
            levelNumber: levelNum,
            persistence: environment.persistence,
            sound: environment.sound,
            haptics: environment.haptics,
            ads: environment.ads,
            analytics: environment.analytics,
            gameCenter: environment.gameCenter,
            goldService: environment.gold,
            diamondService: environment.diamonds,
            piggyBank: environment.piggyBank
        ))
    }
}
