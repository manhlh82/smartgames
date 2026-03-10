import Foundation

/// Central dependency container — all shared services live here.
/// Injected as EnvironmentObjects at app root.
@MainActor
final class AppEnvironment: ObservableObject {
    let persistence = PersistenceService()
    let settings = SettingsService()
    let sound = SoundService()
    let haptics = HapticsService()
    let analytics = AnalyticsService()
    let ads = AdsService()
}
