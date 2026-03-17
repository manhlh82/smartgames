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
        guard case .gamePlay(let gameId, let context) = route, gameId == id else { return nil }

        // Daily challenge info screen
        if context == "daily-info" {
            return AnyView(Stack2048DailyChallengeView(service: environment.stack2048DailyChallenge))
        }

        // Challenge level select grid
        if context == "challengeSelect" {
            return AnyView(Stack2048ChallengeLevelSelectView(persistence: environment.persistence))
        }

        // Daily challenge game (pre-seeded board)
        if context == "daily" {
            let tiles = environment.stack2048DailyChallenge.todayInitialTiles()
                .map { (col: $0.col, value: $0.value) }
            return AnyView(Stack2048GameView(
                persistence: environment.persistence,
                sound: environment.sound,
                haptics: environment.haptics,
                ads: environment.ads,
                analytics: environment.analytics,
                goldService: environment.gold,
                diamondService: environment.diamonds,
                piggyBank: environment.piggyBank,
                dailyInitialTiles: tiles,
                onDailyComplete: { [weak environment] score in
                    environment?.stack2048DailyChallenge.markCompleted(score: score)
                }
            ))
        }

        // Challenge level N
        if context.hasPrefix("challenge-"),
           let n = Int(context.dropFirst(10)),
           let level = Stack2048ChallengeLevelDefinitions.level(n) {
            return AnyView(Stack2048GameView(
                persistence: environment.persistence,
                sound: environment.sound,
                haptics: environment.haptics,
                ads: environment.ads,
                analytics: environment.analytics,
                goldService: environment.gold,
                diamondService: environment.diamonds,
                piggyBank: environment.piggyBank,
                challengeLevel: level
            ))
        }

        // Endless game (default "play" context)
        return AnyView(Stack2048GameView(
            persistence: environment.persistence,
            sound: environment.sound,
            haptics: environment.haptics,
            ads: environment.ads,
            analytics: environment.analytics,
            goldService: environment.gold,
            diamondService: environment.diamonds,
            piggyBank: environment.piggyBank
        ))
    }
}
