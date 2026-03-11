import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject var environment: AppEnvironment
    @EnvironmentObject var gameRegistry: GameRegistry
    @EnvironmentObject var analytics: AnalyticsService

    var body: some View {
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
    }
}
