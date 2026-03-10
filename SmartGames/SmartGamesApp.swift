import SwiftUI

@main
struct SmartGamesApp: App {
    @StateObject private var environment = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment.persistence)
                .environmentObject(environment.settings)
                .environmentObject(environment.sound)
                .environmentObject(environment.analytics)
                .environmentObject(environment.ads)
                .task {
                    // Request AppTrackingTransparency after brief delay
                    // (Apple guidance: don't prompt on cold launch)
                    await requestTrackingPermissionIfNeeded()
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                // TODO: Trigger auto-save via notification center if needed
            }
        }
    }

    /// Request ATT permission. Required before personalized ads can be shown.
    /// Only prompts once per install — OS handles subsequent launches.
    private func requestTrackingPermissionIfNeeded() async {
        // Brief delay so app UI is visible before prompt
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // TODO: When AdMob SDK is integrated, add:
        // import AppTrackingTransparency
        // let status = await ATTrackingManager.requestTrackingAuthorization()
        // environment.analytics.log(AnalyticsEvent(name: "att_permission_response",
        //     parameters: ["status": status == .authorized ? "authorized" : "denied"]))

        // In stub mode: AdMob test IDs don't require ATT
        #if DEBUG
        print("[ATT] Tracking permission would be requested here in production")
        #endif
    }
}
