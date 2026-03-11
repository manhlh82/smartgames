import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject var settings: SettingsService
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var analytics: AnalyticsService
    @EnvironmentObject var sound: SoundService
    @EnvironmentObject var haptics: HapticsService
    @EnvironmentObject var ads: AdsService
    @EnvironmentObject var statistics: StatisticsService
    @EnvironmentObject var gameCenter: GameCenterService
    @EnvironmentObject var dailyChallenge: DailyChallengeService
    @EnvironmentObject var store: StoreService

    var body: some View {
        NavigationStack(path: $router.path) {
            HubView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .sudokuLobby:
                        SudokuLobbyView()
                    case .sudokuGame(let difficulty):
                        sudokuGameDestination(difficulty: difficulty)
                    case .sudokuDailyChallenge:
                        DailyChallengeView(
                            persistence: persistence,
                            analytics: analytics,
                            sound: sound,
                            haptics: haptics,
                            ads: ads,
                            statistics: statistics,
                            gameCenter: gameCenter
                        )
                    case .settings:
                        SettingsView()
                    case .sudokuStatistics:
                        SudokuStatisticsView()
                    }
                }
        }
        .environmentObject(router)
    }

    @ViewBuilder
    private func sudokuGameDestination(difficulty: SudokuDifficulty) -> some View {
        if let puzzle = persistence.load(SudokuPuzzle.self,
                                         key: PersistenceService.Keys.sudokuPendingPuzzle) {
            // Check if this is a daily challenge game and consume the flag
            let isDailyChallenge = persistence.load(Bool.self,
                key: PersistenceService.Keys.sudokuPendingIsDailyChallenge) ?? false
            let dcService: DailyChallengeService? = isDailyChallenge ? dailyChallenge : nil
            SudokuGameView(
                difficulty: difficulty,
                puzzle: puzzle,
                persistence: persistence,
                analytics: analytics,
                sound: sound,
                haptics: haptics,
                ads: ads,
                statisticsService: statistics,
                gameCenterService: gameCenter,
                dailyChallengeService: dcService,
                storeService: store
            )
            .onAppear {
                // Clear the daily-challenge flag after the view is built
                if isDailyChallenge {
                    persistence.delete(key: PersistenceService.Keys.sudokuPendingIsDailyChallenge)
                }
            }
        } else {
            // Fallback: should not happen in normal flow — lobby always saves a pending puzzle.
            Text("Loading puzzle...")
                .onAppear { router.pop() }
        }
    }
}
