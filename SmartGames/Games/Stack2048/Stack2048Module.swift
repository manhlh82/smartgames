import SwiftUI

/// Stack 2048 game module — conforms to GameModule protocol.
/// Endless merge puzzle: drop tiles into 5 columns, chain merges to reach 2048.
@MainActor
final class Stack2048Module: GameModule {
    let id = "stack2048"
    let displayName = "Stack 2048"
    let iconName = "square.stack.fill"
    let isAvailable = true

    var audioConfig: (any AudioConfig)? { Stack2048AudioConfig() }

    var monetizationConfig: MonetizationConfig {
        MonetizationConfig(
            bannerEnabled: true,
            interstitialEnabled: false,
            interstitialFrequency: 0,
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
        AnyView(Stack2048LobbyView(
            persistence: environment.persistence,
            ads: environment.ads,
            analytics: environment.analytics
        ))
    }

    func navigationDestination(for route: AppRoute, environment: AppEnvironment) -> AnyView? {
        switch route {
        case .gamePlay(let gameId, _) where gameId == id:
            return AnyView(Stack2048GameView(
                persistence: environment.persistence,
                sound: environment.sound,
                haptics: environment.haptics,
                ads: environment.ads,
                analytics: environment.analytics,
                goldService: environment.gold,
                diamondService: environment.diamonds
            ))
        default:
            return nil
        }
    }
}
