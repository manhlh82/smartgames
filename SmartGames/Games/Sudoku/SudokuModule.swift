import SwiftUI

/// Sudoku game module — conforms to GameModule protocol.
/// Owns Sudoku-specific services (ThemeService, StatisticsService).
@MainActor
final class SudokuGameModule: GameModule {
    let id = "sudoku"
    let displayName = "Sudoku"
    let iconName = "icon-sudoku"
    let isAvailable = true

    var monetizationConfig: MonetizationConfig {
        MonetizationConfig(
            bannerEnabled: true,
            interstitialEnabled: true,
            interstitialFrequency: 1,
            rewardedHintsEnabled: true,
            rewardedHintAmount: 3,
            levelCompleteHintReward: 1,
            maxHintCap: 3,
            mistakeResetEnabled: true,
            mistakeResetUsesPerLevel: 1
        )
    }

    let themeService: ThemeService
    let statisticsService: StatisticsService

    init(persistence: PersistenceService) {
        self.themeService = ThemeService(persistence: persistence)
        self.statisticsService = StatisticsService(persistence: persistence)
    }

    func makeLobbyView(environment: AppEnvironment) -> AnyView {
        AnyView(
            SudokuLobbyView(persistence: environment.persistence)
                .environmentObject(themeService)
                .environmentObject(statisticsService)
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
        // Daily challenge
        if context == "daily" {
            return AnyView(
                DailyChallengeView(
                    persistence: environment.persistence,
                    analytics: environment.analytics,
                    sound: environment.sound,
                    haptics: environment.haptics,
                    ads: environment.ads,
                    statistics: statisticsService,
                    gameCenter: environment.gameCenter
                )
                .environmentObject(themeService)
                .environmentObject(statisticsService)
            )
        }
        // Statistics
        if context == "statistics" {
            return AnyView(
                SudokuStatisticsView()
                    .environmentObject(themeService)
                    .environmentObject(statisticsService)
            )
        }
        // Game by difficulty (context = rawValue of SudokuDifficulty)
        guard let difficulty = SudokuDifficulty(rawValue: context) else { return nil }
        return AnyView(sudokuGameView(difficulty: difficulty, environment: environment))
    }

    @ViewBuilder
    private func sudokuGameView(difficulty: SudokuDifficulty, environment: AppEnvironment) -> some View {
        if let puzzle = environment.persistence.load(SudokuPuzzle.self,
                                                      key: PersistenceService.Keys.sudokuPendingPuzzle) {
            let isDailyChallenge = environment.persistence.load(Bool.self,
                key: PersistenceService.Keys.sudokuPendingIsDailyChallenge) ?? false
            let dcService: DailyChallengeService? = isDailyChallenge ? environment.dailyChallenge : nil
            SudokuGameView(
                difficulty: difficulty,
                puzzle: puzzle,
                persistence: environment.persistence,
                analytics: environment.analytics,
                sound: environment.sound,
                haptics: environment.haptics,
                ads: environment.ads,
                statisticsService: statisticsService,
                gameCenterService: environment.gameCenter,
                dailyChallengeService: dcService,
                storeService: environment.store,
                monetizationConfig: monetizationConfig
            )
            .environmentObject(themeService)
            .onAppear {
                if isDailyChallenge {
                    environment.persistence.delete(key: PersistenceService.Keys.sudokuPendingIsDailyChallenge)
                }
            }
        } else {
            Text("Loading puzzle...")
        }
    }
}
