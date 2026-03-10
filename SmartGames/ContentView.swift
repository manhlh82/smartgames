import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject var settings: SettingsService

    var body: some View {
        NavigationStack(path: $router.path) {
            HubView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .sudokuLobby:
                        SudokuLobbyView()
                    case .sudokuGame(let difficulty):
                        // Placeholder — implemented in PR-05
                        Text("Game: \(difficulty.displayName)")
                            .navigationTitle(difficulty.displayName)
                    case .settings:
                        SettingsView()
                    }
                }
        }
        .environmentObject(router)
    }
}
