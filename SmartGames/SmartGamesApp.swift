import SwiftUI

@main
struct SmartGamesApp: App {
    @StateObject private var environment = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                // AppEnvironment (single object with all shared services)
                .environmentObject(environment)
                // Individual services injected for views that use @EnvironmentObject directly
                .environmentObject(environment.persistence)
                .environmentObject(environment.settings)
                .environmentObject(environment.sound)
                .environmentObject(environment.haptics)
                .environmentObject(environment.analytics)
                .environmentObject(environment.ads)
                .environmentObject(environment.gameCenter)
                .environmentObject(environment.dailyChallenge)
                .environmentObject(environment.store)
                .environmentObject(environment.gameRegistry)
                .environmentObject(environment.localization)
                .environmentObject(environment.gold)
                .environmentObject(environment.themeService)
                .task {
                    // Authenticate Game Center silently on launch
                    environment.gameCenter.authenticate()
                    // Start StoreKit 2 background transaction listener
                    let _ = environment.store.listenForTransactions()
                    // Refresh entitlements on launch (e.g. family sharing, refunds)
                    await environment.store.updateEntitlements()
                    // Request AppTrackingTransparency after brief delay
                    await requestTrackingPermissionIfNeeded()
                    // Schedule daily 8 AM reminder notification (only if permitted)
                    await scheduleDailyReminderIfNeeded()
                }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background, .inactive:
                // Pause background music when app leaves foreground
                environment.sound.pauseBackgroundMusic()
            case .active:
                // Resume background music when app returns to foreground
                environment.sound.resumeBackgroundMusic()
            default:
                break
            }
        }
    }

    /// Schedule daily 8 AM reminder if the user has (or grants) notification permission.
    private func scheduleDailyReminderIfNeeded() async {
        let granted = await environment.dailyChallenge.requestNotificationPermission()
        if granted {
            environment.dailyChallenge.scheduleReminderNotification(at: 8)
        }
    }

    /// Request ATT permission. Required before personalized ads can be shown.
    private func requestTrackingPermissionIfNeeded() async {
        // Brief delay so app UI is visible before prompt
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        #if DEBUG
        print("[ATT] Tracking permission would be requested here in production")
        #endif
    }
}
