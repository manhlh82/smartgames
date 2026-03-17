import SwiftUI

/// Crossword game module — conforms to GameModule protocol.
@MainActor
final class CrosswordModule: GameModule {
    let id = "crossword"
    let displayName = "Crossword"
    let iconName = "puzzlepiece.fill"  // SF Symbol fallback (no custom asset)
    let isAvailable = true

    var audioConfig: (any AudioConfig)? { nil }

    var monetizationConfig: MonetizationConfig {
        MonetizationConfig(
            bannerEnabled: true,
            interstitialEnabled: true,
            interstitialFrequency: 2,
            rewardedHintsEnabled: true,
            rewardedHintAmount: 3,
            levelCompleteHintReward: 1,
            maxHintCap: 5,
            mistakeResetEnabled: false
        )
    }

    private let puzzleBank: CrosswordPuzzleBank

    init(persistence: PersistenceService) {
        self.puzzleBank = CrosswordPuzzleBank(persistence: persistence)
    }

    func makeLobbyView(environment: AppEnvironment) -> AnyView {
        AnyView(
            CrosswordLobbyView(
                puzzleBank: puzzleBank,
                persistence: environment.persistence
            )
            .environmentObject(environment.crosswordDailyChallenge)
        )
    }

    func navigationDestination(for route: AppRoute, environment: AppEnvironment) -> AnyView? {
        switch route {
        case .gamePlay(let gameId, let context) where gameId == id:
            return resolveGamePlay(context: context, environment: environment)
        default:
            return nil
        }
    }

    // MARK: - Private

    private func resolveGamePlay(context: String, environment: AppEnvironment) -> AnyView? {
        guard let puzzle = environment.persistence.load(
            CrosswordPuzzle.self, key: PersistenceService.Keys.crosswordPendingPuzzle
        ) else {
            return AnyView(Text("Loading puzzle..."))
        }
        let isDailyChallenge = environment.persistence.load(
            Bool.self, key: PersistenceService.Keys.crosswordPendingIsDailyChallenge
        ) ?? false
        let dcService: CrosswordDailyChallengeService? = isDailyChallenge
            ? environment.crosswordDailyChallenge : nil

        return AnyView(
            CrosswordGameView(
                puzzle: puzzle,
                persistence: environment.persistence,
                analytics: environment.analytics,
                sound: environment.sound,
                haptics: environment.haptics,
                ads: environment.ads,
                goldService: environment.gold,
                diamondService: environment.diamonds,
                monetizationConfig: monetizationConfig,
                dailyChallengeService: dcService,
                gameCenterService: environment.gameCenter
            )
            .onAppear {
                if isDailyChallenge {
                    environment.persistence.delete(
                        key: PersistenceService.Keys.crosswordPendingIsDailyChallenge)
                }
            }
        )
    }
}
