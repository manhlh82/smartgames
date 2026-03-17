import SwiftUI
import Combine

/// Phase state machine for Stack 2048 gameplay.
enum Stack2048Phase: Equatable {
    case playing
    case paused
    case hammerMode     // player selects a tile to destroy
    case watchingAd     // waiting for rewarded ad to complete
    case gameOver
}

/// Lightweight merge animation trigger — consumed by the board view.
struct MergeEffect: Identifiable {
    let id = UUID()
    let column: Int
    let row: Int        // 0 = top
    let value: Int
}

/// Drives Stack 2048 gameplay: state machine, power-ups, persistence, analytics, gold rewards.
@MainActor
final class Stack2048GameViewModel: ObservableObject {
    @Published private(set) var phase: Stack2048Phase = .playing
    @Published private(set) var gameState: Stack2048GameState
    @Published private(set) var highScore: Int = 0
    @Published private(set) var isNewHighScore: Bool = false
    @Published private(set) var goldEarnedOnEnd: Int = 0
    @Published var mergeEffects: [MergeEffect] = []

    let persistence: PersistenceService
    let sound: SoundService
    let haptics: HapticsService
    let ads: AdsService
    let analytics: AnalyticsService
    let goldService: GoldService

    private var engine = Stack2048Engine()
    private var milestonesTileLogged = Set<Int>()

    // MARK: - Init

    init(
        persistence: PersistenceService,
        sound: SoundService,
        haptics: HapticsService,
        ads: AdsService,
        analytics: AnalyticsService,
        goldService: GoldService
    ) {
        self.persistence = persistence
        self.sound = sound
        self.haptics = haptics
        self.ads = ads
        self.analytics = analytics
        self.goldService = goldService
        self.gameState = engine.state
        let progress = persistence.load(Stack2048Progress.self, key: PersistenceService.Keys.stack2048Progress) ?? Stack2048Progress()
        self.highScore = progress.highScore
        analytics.log(.stack2048GameStarted())
    }

    // MARK: - Player Input

    func dropTile(into column: Int) {
        guard phase == .playing, gameState.canDrop(into: column) else { return }

        let events = engine.dropTile(into: column)
        gameState = engine.state

        for event in events {
            handleEngineEvent(event)
        }
    }

    /// Tap a tile while in hammer mode to destroy it (spends 150 Gold on first tap).
    func tapTileForHammer(column: Int, row: Int) {
        guard phase == .hammerMode else { return }
        guard goldService.spend(amount: 150) else { return }

        analytics.log(.stack2048PowerUpUsed(type: "hammer", goldSpent: 150))
        sound.playSFX("stack2048-hammer")
        haptics.impact(.medium)

        let events = engine.removeTile(at: column, row: row)
        gameState = engine.state
        phase = .playing

        for event in events {
            handleEngineEvent(event)
        }
    }

    // MARK: - Power-ups

    /// Enter hammer mode if player has enough Gold. Gold is spent when a tile is tapped.
    func useHammer() {
        guard phase == .playing, goldService.balance >= 150 else { return }
        phase = .hammerMode
    }

    func cancelHammer() {
        guard phase == .hammerMode else { return }
        phase = .playing
    }

    /// Spend 200 Gold to replace the queued next tile.
    func useShuffle() {
        guard phase == .playing else { return }
        guard goldService.spend(amount: 200) else { return }

        engine.replaceNextTile()
        gameState = engine.state
        analytics.log(.stack2048PowerUpUsed(type: "shuffle", goldSpent: 200))
        haptics.impact(.light)
    }

    /// Watch a rewarded ad to earn +100 Gold.
    func requestAdGold() {
        guard phase == .playing, ads.isRewardedAdReady else { return }
        phase = .watchingAd
        ads.showRewardedAd { [weak self] didEarn in
            guard let self else { return }
            if didEarn {
                self.goldService.earn(amount: 100)
                self.analytics.log(.goldEarned(amount: 100, source: "stack2048_ad", balanceAfter: self.goldService.balance))
            }
            self.phase = .playing
        }
    }

    // MARK: - Pause / Resume

    func pause() {
        guard phase == .playing else { return }
        phase = .paused
        analytics.log(.stack2048Paused(score: gameState.score))
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .playing
    }

    // MARK: - Retry / Quit

    func retry() {
        engine.reset()
        gameState = engine.state
        mergeEffects = []
        isNewHighScore = false
        goldEarnedOnEnd = 0
        milestonesTileLogged = []
        phase = .playing
        analytics.log(.stack2048GameStarted())
    }

    func quit() {
        analytics.log(.stack2048Quit(score: gameState.score))
    }

    // MARK: - Engine Events

    private func handleEngineEvent(_ event: Stack2048EngineEvent) {
        switch event {
        case .tilePlaced:
            sound.playSFX("stack2048-place")
            haptics.impact(.light)

        case .tileMerged(let column, let row, let newValue):
            let sfx = newValue >= 512 ? "stack2048-merge-big" : "stack2048-merge"
            sound.playSFX(sfx)
            haptics.impact(.medium)
            spawnMergeEffect(column: column, row: row, value: newValue)
            logMilestoneTileIfNeeded(newValue)

        case .gameOver:
            handleGameOver()
        }
    }

    private func handleGameOver() {
        phase = .gameOver
        sound.playSFX("stack2048-gameover")
        haptics.notification(.error)

        let score = gameState.score
        let maxTile = gameState.maxTileValue
        var progress = persistence.load(Stack2048Progress.self, key: PersistenceService.Keys.stack2048Progress) ?? Stack2048Progress()
        let wasHighScore = score > progress.highScore
        progress.recordResult(score: score, maxTile: maxTile)
        persistence.save(progress, key: PersistenceService.Keys.stack2048Progress)

        isNewHighScore = wasHighScore
        if wasHighScore { highScore = score }

        let base = GoldReward.stack2048GameOver
        let bonus = wasHighScore ? GoldReward.stack2048HighScoreBonus : 0
        let total = base + bonus
        goldEarnedOnEnd = total
        goldService.earn(amount: total)
        analytics.log(.goldEarned(amount: total, source: "stack2048", balanceAfter: goldService.balance))
        analytics.log(.stack2048GameOver(score: score, maxTile: maxTile, gamesPlayed: progress.gamesPlayed))
    }

    // MARK: - Helpers

    private func spawnMergeEffect(column: Int, row: Int, value: Int) {
        let effect = MergeEffect(column: column, row: row, value: value)
        mergeEffects.append(effect)
        let eid = effect.id
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            mergeEffects.removeAll { $0.id == eid }
        }
    }

    private func logMilestoneTileIfNeeded(_ value: Int) {
        let milestones: Set<Int> = [512, 1024, 2048, 4096]
        guard milestones.contains(value), !milestonesTileLogged.contains(value) else { return }
        milestonesTileLogged.insert(value)
        analytics.log(.stack2048MilestoneTile(value: value))
    }
}
