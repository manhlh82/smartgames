import Foundation

/// Central dependency container — truly shared services (cross-game).
/// Game-specific services live in their respective GameModule.
@MainActor
final class AppEnvironment: ObservableObject {
    let persistence: PersistenceService
    let settings: SettingsService
    let sound: SoundService
    let haptics: HapticsService
    let analytics: AnalyticsService
    let ads: AdsService
    let gameCenter: GameCenterService
    let dailyChallenge: DailyChallengeService
    let store: StoreService
    let gameRegistry: GameRegistry
    let localization: LocalizationService
    let gold: GoldService
    let themeService: ThemeService

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
        self.gameCenter = GameCenterService()
        self.dailyChallenge = DailyChallengeService(persistence: persistence)
        self.store = StoreService()
        // Wire store into ads so ads are skipped when Remove Ads is purchased
        adsService.storeService = self.store

        self.localization = LocalizationService(persistence: persistence)

        // Shared Gold and theme services (cross-game)
        let gold = GoldService(persistence: persistence)
        self.gold = gold
        self.themeService = ThemeService(persistence: persistence, goldService: gold)

        // Register game modules
        let registry = GameRegistry()
        let sudoku = SudokuGameModule(persistence: persistence)
        registry.register(sudoku)
        let dropRush = DropRushModule(persistence: persistence)
        registry.register(dropRush)
        self.gameRegistry = registry
    }
}
