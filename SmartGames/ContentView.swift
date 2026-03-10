import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject var settings: SettingsService
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var analytics: AnalyticsService
    @EnvironmentObject var sound: SoundService
    @EnvironmentObject var haptics: HapticsService
    @EnvironmentObject var ads: AdsService

    var body: some View {
        NavigationStack(path: $router.path) {
            HubView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .sudokuLobby:
                        SudokuLobbyView()
                    case .sudokuGame(let difficulty):
                        sudokuGameDestination(difficulty: difficulty)
                    case .settings:
                        SettingsView()
                    }
                }
        }
        .environmentObject(router)
    }

    @ViewBuilder
    private func sudokuGameDestination(difficulty: SudokuDifficulty) -> some View {
        if let puzzle = persistence.load(SudokuPuzzle.self,
                                         key: PersistenceService.Keys.sudokuPendingPuzzle) {
            SudokuGameView(
                difficulty: difficulty,
                puzzle: puzzle,
                persistence: persistence,
                analytics: analytics,
                sound: sound,
                haptics: haptics,
                ads: ads
            )
        } else {
            // Fallback: should not happen in normal flow — lobby always saves a pending puzzle.
            Text("Loading puzzle...")
                .onAppear { router.pop() }
        }
    }
}
