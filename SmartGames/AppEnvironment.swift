import Foundation

/// Central dependency container — all shared services live here.
/// Injected as EnvironmentObjects at app root.
@MainActor
final class AppEnvironment: ObservableObject {
    let persistence: PersistenceService
    let settings: SettingsService
    let sound: SoundService
    let haptics: HapticsService
    let analytics: AnalyticsService
    let ads: AdsService

    init() {
        let persistence = PersistenceService()
        let settings = SettingsService(persistence: persistence)
        let sound = SoundService()
        let haptics = HapticsService()

        // Wire settings into services
        sound.configure(settings: settings)
        haptics.configure(settings: settings)

        self.persistence = persistence
        self.settings = settings
        self.sound = sound
        self.haptics = haptics
        self.analytics = AnalyticsService()
        self.ads = AdsService()
    }
}
