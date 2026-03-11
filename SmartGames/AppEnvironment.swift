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
    let theme: ThemeService
    let statistics: StatisticsService
    let gameCenter: GameCenterService
    let dailyChallenge: DailyChallengeService
    let store: StoreService

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
        let adsService = AdsService()
        self.ads = adsService
        self.theme = ThemeService(persistence: persistence)
        self.statistics = StatisticsService(persistence: persistence)
        self.gameCenter = GameCenterService()
        self.dailyChallenge = DailyChallengeService(persistence: persistence)
        self.store = StoreService()
        // Wire store into ads so ads are skipped when Remove Ads is purchased
        adsService.storeService = self.store
    }
}
