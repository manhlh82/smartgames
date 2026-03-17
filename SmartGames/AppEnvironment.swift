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
    let diamonds: DiamondService
    let adRewardTracker: AdRewardTracker
    let dailyLogin: DailyLoginRewardService
    let piggyBank: PiggyBankService
    let starterPack: StarterPackService
    let consecutiveLoss: ConsecutiveLossService
    let themeService: ThemeService
    let weeklyChallenge: WeeklyChallengeService
    let dropRushDailyChallenge: DropRushDailyChallengeService
    let stack2048DailyChallenge: Stack2048DailyChallengeService

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
        // Economy weak refs wired below after gold/diamond services are initialised

        self.localization = LocalizationService(persistence: persistence)

        // Shared Gold, Diamond, economy and theme services (cross-game)
        let gold = GoldService(persistence: persistence)
        self.gold = gold
        let diamonds = DiamondService(persistence: persistence)
        self.diamonds = diamonds
        self.adRewardTracker = AdRewardTracker(persistence: persistence)
        self.dailyLogin = DailyLoginRewardService(
            persistence: persistence,
            goldService: gold,
            diamondService: diamonds
        )
        self.piggyBank = PiggyBankService(persistence: persistence)
        let starterPack = StarterPackService(persistence: persistence)
        self.starterPack = starterPack
        self.consecutiveLoss = ConsecutiveLossService(starterPack: starterPack)
        let themeService = ThemeService(persistence: persistence, goldService: gold)
        self.themeService = themeService

        // Wire economy services into ads (daily cap + diamond drops)
        adsService.adRewardTracker = self.adRewardTracker
        adsService.diamondService = diamonds
        // Wire diamond service into theme service for legendary purchases
        themeService.diamondService = diamonds

        self.weeklyChallenge = WeeklyChallengeService(
            persistence: persistence,
            goldService: gold,
            diamondService: diamonds,
            gameCenter: self.gameCenter
        )
        self.dropRushDailyChallenge = DropRushDailyChallengeService(
            persistence: persistence,
            gold: gold,
            gameCenter: self.gameCenter
        )
        self.stack2048DailyChallenge = Stack2048DailyChallengeService(
            persistence: persistence,
            gold: gold,
            gameCenter: self.gameCenter
        )

        // Grant diamonds on first app launch (onboarding)
        if !persistence.exists(key: PersistenceService.Keys.diamondOnboardingGranted) {
            diamonds.earn(amount: EconomyConfig.onboardingDiamondGrant)
            persistence.save(true, key: PersistenceService.Keys.diamondOnboardingGranted)
        }

        // Register game modules
        let registry = GameRegistry()
        let sudoku = SudokuGameModule(persistence: persistence)
        registry.register(sudoku)
        let dropRush = DropRushModule(persistence: persistence)
        registry.register(dropRush)
        let stack2048 = Stack2048Module(persistence: persistence)
        registry.register(stack2048)
        self.gameRegistry = registry
    }
}
