import SwiftUI
import Combine

/// Phase state machine for Stack 2048 gameplay.
enum Stack2048Phase: Equatable {
    case playing
    case paused
    case hammerMode     // player selects a tile to destroy
    case watchingAd     // waiting for rewarded ad to complete
    case gameOver
    case won            // player created a 2048 tile
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
    // phase, highScore, isNewHighScore, goldEarnedOnEnd are also mutated by the +GameEvents extension
    @Published var phase: Stack2048Phase = .playing
    @Published private(set) var gameState: Stack2048GameState
    @Published var highScore: Int = 0
    @Published var isNewHighScore: Bool = false
    @Published var goldEarnedOnEnd: Int = 0
    @Published var mergeEffects: [MergeEffect] = []
    @Published var dragTargetColumn: Int? = nil

    let persistence: PersistenceService
    let sound: SoundService
    let haptics: HapticsService
    let ads: AdsService
    let analytics: AnalyticsService
    let goldService: GoldService

    var engine = Stack2048Engine()
    var milestonesTileLogged = Set<Int>()
    var hasWonThisSession = false

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

    // MARK: - Drag-and-Drop

    func setDragTarget(_ column: Int?) {
        dragTargetColumn = column
    }

    func confirmDrop(into column: Int) {
        dropTile(into: column)
        dragTargetColumn = nil
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
        hasWonThisSession = false
        phase = .playing
        analytics.log(.stack2048GameStarted())
    }

    func keepPlaying() {
        guard phase == .won else { return }
        phase = .playing
    }

    func quit() {
        analytics.log(.stack2048Quit(score: gameState.score))
    }

}
