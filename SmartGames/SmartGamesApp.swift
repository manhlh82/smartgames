import SwiftUI

@main
struct SmartGamesApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment.persistence)
                .environmentObject(environment.settings)
                .environmentObject(environment.sound)
                .environmentObject(environment.analytics)
                .environmentObject(environment.ads)
        }
    }
}
