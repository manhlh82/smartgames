import SwiftUI
import Combine

/// Phase state machine for Drop Rush gameplay.
enum DropRushPhase: Equatable {
    case countdown
    case playing
    case paused
    case watchingAd
    case levelComplete
    case gameOver
}

/// Drives Drop Rush gameplay: game loop, input, state transitions, persistence, analytics.
@MainActor
final class DropRushGameViewModel: ObservableObject {
    @Published var phase: DropRushPhase = .countdown
    @Published var engineState: EngineState
    @Published private(set) var countdownValue: Int = 3
    @Published var stars: Int = 0
    @Published var isNewHighScore: Bool = false
    @Published var continueAvailable: Bool = false
    @Published var hitEffects: [HitEffect] = []
    @Published var showSpeedUpFlash: Bool = false
    @Published private(set) var showPerfectAccuracy: Bool = false

    // Internal access so +Actions extension can write these
    var engine: DropRushEngine
    var lastTickDate: Date?
    var countdownTask: Task<Void, Never>?
    var continueUsedThisAttempt = false
    private var speedUpFlashTask: Task<Void, Never>?

    let config: LevelConfig
    let levelNumber: Int
    /// Running count of successful hits for move-streak gold bonus.
    var hitCount: Int = 0
    let persistence: PersistenceService
    let sound: SoundService
    let haptics: HapticsService
    let ads: AdsService
    let analytics: AnalyticsService
    let gameCenter: GameCenterService
    let goldService: GoldService
    let diamondService: DiamondService
    let piggyBank: PiggyBankService
    /// Gold earned on the most recent level complete — 0 until level is won.
    @Published private(set) var goldEarnedOnWin: Int = 0

    private var levelsCompletedThisSession = 0

    init(
        levelNumber: Int,
        persistence: PersistenceService,
        sound: SoundService,
        haptics: HapticsService,
        ads: AdsService,
        analytics: AnalyticsService,
        gameCenter: GameCenterService,
        goldService: GoldService,
        diamondService: DiamondService,
        piggyBank: PiggyBankService
    ) {
        self.levelNumber = levelNumber
        self.persistence = persistence
        self.sound = sound
        self.haptics = haptics
        self.ads = ads
        self.analytics = analytics
        self.gameCenter = gameCenter
        self.goldService = goldService
        self.diamondService = diamondService
        self.piggyBank = piggyBank
        let cfg = LevelDefinitions.level(levelNumber) ?? LevelDefinitions.levels[0]
        self.config = cfg
        self.engine = DropRushEngine(config: cfg)
        self.engineState = EngineState()
        startCountdown()
    }

    // MARK: - Computed

    var symbols: [String] { config.symbolPool }

    // MARK: - Countdown

    func startCountdown() {
        phase = .countdown
        countdownValue = 3
        lastTickDate = nil
        countdownTask?.cancel()
        countdownTask = Task { @MainActor [weak self] in
            for count in stride(from: 3, through: 1, by: -1) {
                guard let self, !Task.isCancelled else { return }
                self.countdownValue = count
                try? await Task.sleep(nanoseconds: 900_000_000)
            }
            guard let self, !Task.isCancelled else { return }
            self.countdownValue = 0
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            self.analytics.log(.dropRushLevelStarted(level: self.levelNumber))
            self.phase = .playing
        }
    }

    // MARK: - Game Loop

    /// Called each frame by TimelineView. Advances engine by delta seconds.
    func tick(date: Date) {
        guard phase == .playing else { return }
        let delta = lastTickDate.map { date.timeIntervalSince($0) } ?? 0
        lastTickDate = date
        let clamped = min(max(delta, 0), 0.1)

        let events = engine.tick(deltaTime: clamped)
        engineState = engine.state

        for event in events {
            handleEvent(event)
        }
    }

    func handleEvent(_ event: GameEvent) {
        switch event {
        case .objectMissed:
            sound.playSFX("dropRush-miss")
            haptics.notification(.warning)
        case .levelComplete(let score, let hits, let misses):
            let s = starsForAccuracy(hits: hits, misses: misses)
            stars = s
            showPerfectAccuracy = misses == 0 && hits > 0
            let isNewBest = saveProgress(score: score, stars: s)
            sound.playSFX("dropRush-level-complete")
            haptics.notification(.success)
            let accuracy = Double(hits) / Double(max(hits + misses, 1))
            analytics.log(.dropRushLevelCompleted(level: levelNumber, score: score, stars: s, accuracy: accuracy))
            if isNewBest {
                let cumulative = loadCumulativeScore()
                gameCenter.submitScore(cumulative, leaderboardID: "com.smartgames.dropRush.leaderboard.cumulative")
            }
            // Grant Gold reward for level completion
            let baseGold = GoldReward.dropRushComplete
            let bonusGold = s >= 3 ? GoldReward.dropRushThreeStarBonus : 0
            let totalGold = baseGold + bonusGold
            goldEarnedOnWin = totalGold
            goldService.earn(amount: totalGold)
            analytics.log(.goldEarned(amount: totalGold, source: "dropRush",
                                      balanceAfter: goldService.balance))
            levelsCompletedThisSession += 1
            if levelsCompletedThisSession % 2 == 0 {
                ads.showInterstitialIfReady()
            }
            piggyBank.recordGameCompleted()
            phase = .levelComplete
        case .gameOver:
            sound.playSFX("dropRush-gameover")
            haptics.notification(.error)
            analytics.log(.dropRushLevelFailed(level: levelNumber, score: engineState.score, misses: engineState.misses))
            continueAvailable = !continueUsedThisAttempt && ads.isRewardedAdReady
            phase = .gameOver
        case .speedPhaseChanged:
            sound.playSFX("dropRush-speedup")
            haptics.impact(.medium)
            triggerSpeedUpFlash()
        default:
            break
        }
    }

    // MARK: - Player Input

    func handleTap(symbol: String) {
        guard phase == .playing else { return }
        let result = engine.handleTap(symbol: symbol)
        engineState = engine.state
        switch result {
        case .hit(_, let normalizedY, let lane, let symbol):
            sound.playSFX("dropRush-hit")
            haptics.impact(.light)
            spawnHitEffect(normalizedY: normalizedY, lane: lane, symbol: symbol)
            // Move-streak bonus: every N hits grant a small gold bonus
            hitCount += 1
            if hitCount % EconomyConfig.moveStreakInterval == 0 {
                goldService.earn(amount: EconomyConfig.moveStreakBonus)
                analytics.log(.goldEarned(amount: EconomyConfig.moveStreakBonus, source: "move_streak", balanceAfter: goldService.balance))
            }
        case .damaged:
            // First hit on an armored object — ring removed, object remains on screen
            sound.playSFX("dropRush-hit")
            haptics.impact(.medium)
        case .noTarget:
            sound.playSFX("dropRush-wrong")
            haptics.notification(.warning)
            // Wrong tap may have consumed the last life
            if engine.state.isGameOver {
                analytics.log(.dropRushLevelFailed(level: levelNumber, score: engineState.score, misses: engineState.misses))
                continueAvailable = !continueUsedThisAttempt && ads.isRewardedAdReady
                phase = .gameOver
            }
        }
    }

    // MARK: - Pause / Resume

    func pause() {
        guard phase == .playing else { return }
        phase = .paused
        lastTickDate = nil
        analytics.log(.dropRushPaused(level: levelNumber, elapsed: engine.state.elapsedTime))
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .playing
        lastTickDate = nil
    }

    // MARK: - Retry

    func retry() {
        countdownTask?.cancel()
        engine.reset()
        engineState = engine.state
        stars = 0
        isNewHighScore = false
        showPerfectAccuracy = false
        continueAvailable = false
        continueUsedThisAttempt = false
        goldEarnedOnWin = 0
        hitEffects = []
        speedUpFlashTask?.cancel()
        showSpeedUpFlash = false
        startCountdown()
    }

    // MARK: - Hit Effects

    private func spawnHitEffect(normalizedY: CGFloat, lane: Int, symbol: String) {
        let laneCount = CGFloat(max(config.symbolPool.count, 1))
        let normalizedX = (CGFloat(lane) + 0.5) / laneCount
        let color = DropRushColors.color(for: symbol)
        let effect = HitEffect(normalizedX: normalizedX, normalizedY: normalizedY, color: color)
        hitEffects.append(effect)
        let effectId = effect.id
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            hitEffects.removeAll { $0.id == effectId }
        }
    }

    // MARK: - Speed Up Flash

    private func triggerSpeedUpFlash() {
        speedUpFlashTask?.cancel()
        showSpeedUpFlash = true
        speedUpFlashTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            showSpeedUpFlash = false
        }
    }

    // MARK: - Persistence

    /// Saves progress. Returns true if a new cumulative high score was set.
    @discardableResult
    private func saveProgress(score: Int, stars: Int) -> Bool {
        var progress = persistence.load(DropRushProgress.self, key: PersistenceService.Keys.dropRushProgress) ?? DropRushProgress()
        let previousScore = progress.levelHighScores[levelNumber] ?? 0
        isNewHighScore = score > previousScore
        progress.recordResult(level: levelNumber, stars: stars, score: score)
        persistence.save(progress, key: PersistenceService.Keys.dropRushProgress)
        return isNewHighScore
    }

    private func loadCumulativeScore() -> Int {
        let progress = persistence.load(DropRushProgress.self, key: PersistenceService.Keys.dropRushProgress) ?? DropRushProgress()
        return progress.cumulativeHighScore
    }
}
