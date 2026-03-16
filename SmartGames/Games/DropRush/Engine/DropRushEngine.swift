import Foundation

/// Pure-logic game engine for Drop Rush.
/// Zero UIKit/SwiftUI imports — fully testable in isolation.
/// The ViewModel drives the game loop by calling tick(deltaTime:) each frame.
final class DropRushEngine {
    var state: EngineState
    private let config: LevelConfig
    private var spawnScheduler: SpawnScheduler

    init(config: LevelConfig) {
        self.config = config
        self.state = EngineState()
        self.spawnScheduler = SpawnScheduler()
    }

    // MARK: - Game Loop

    /// Advance simulation by deltaTime seconds. Returns events that occurred this tick.
    /// Call this every frame from the ViewModel (e.g. from a TimelineView schedule).
    @discardableResult
    func tick(deltaTime: TimeInterval) -> [GameEvent] {
        guard !state.isGameOver && !state.isComplete else { return [] }

        var events: [GameEvent] = []
        state.elapsedTime += deltaTime

        // 1. Update speed phase
        let newMultiplier = resolvedSpeedMultiplier(elapsed: state.elapsedTime)
        if newMultiplier != state.currentSpeedMultiplier {
            state.currentSpeedMultiplier = newMultiplier
            events.append(.speedPhaseChanged(multiplier: newMultiplier))
        }

        // 2. Move all objects downward
        let effectiveSpeed = state.currentSpeedMultiplier
        for i in state.fallingObjects.indices {
            state.fallingObjects[i].normalizedY +=
                state.fallingObjects[i].speed * CGFloat(deltaTime) * effectiveSpeed
        }

        // 3. Emit danger events for objects approaching (but not yet at) ground
        for obj in state.fallingObjects where obj.normalizedY > 0.85 && obj.normalizedY < 1.0 {
            events.append(.objectInDanger(id: obj.id))
        }

        // 4. Collect objects that reached the ground (normalizedY >= 1.0)
        let grounded = state.fallingObjects.filter { $0.normalizedY >= 1.0 }
        for obj in grounded {
            state.misses += 1
            state.livesRemaining -= 1
            // Record miss time for grace-period on wrong-tap detection
            state.recentlyMissedSymbols[obj.symbol] = state.elapsedTime
            events.append(.objectMissed(id: obj.id, symbol: obj.symbol))
        }
        state.fallingObjects.removeAll { $0.normalizedY >= 1.0 }
        // Evict grace-period entries older than 1 second
        state.recentlyMissedSymbols = state.recentlyMissedSymbols.filter { state.elapsedTime - $0.value < 1.0 }

        // 5. Reset combo when any object is missed
        if !grounded.isEmpty {
            state.comboCount = 0
            state.comboMultiplier = 1.0
        }

        // 6. Check game over after processing misses
        if state.livesRemaining <= 0 {
            state.isGameOver = true
            events.append(.gameOver)
            return events
        }

        // 7. Try to spawn new objects (may return 1 or 2)
        let spawned = spawnScheduler.trySpawn(
            elapsed: state.elapsedTime,
            config: config,
            objectsSpawned: state.objectsSpawned,
            onScreenCount: state.fallingObjects.count
        )
        for obj in spawned {
            state.fallingObjects.append(obj)
            state.objectsSpawned += 1
            events.append(.objectSpawned(obj))
        }

        // 8. Check level complete: all objects spawned and screen is clear
        if state.objectsSpawned >= config.totalObjects && state.fallingObjects.isEmpty {
            state.isComplete = true
            state.comboCount = 0
            state.comboMultiplier = 1.0
            events.append(.levelComplete(
                score: state.score,
                hits: state.hits,
                misses: state.misses
            ))
        }

        return events
    }

    // MARK: - Player Input

    /// Handle a tap on a symbol button.
    /// For normal objects: destroys on first tap.
    /// For armored objects: first tap removes the ring; second tap destroys.
    @discardableResult
    func handleTap(symbol: String) -> TapResult {
        // Target = matching symbol with highest normalizedY (closest to ground), by index
        guard let idx = state.fallingObjects.indices
            .filter({ state.fallingObjects[$0].symbol == symbol })
            .max(by: { state.fallingObjects[$0].normalizedY < state.fallingObjects[$1].normalizedY })
        else {
            state.wrongTaps += 1
            // Grace period: if this symbol just fell off screen (within 0.5s), don't penalise —
            // the player tapped correctly but lost the race against the engine tick.
            let justMissed = state.recentlyMissedSymbols[symbol].map { state.elapsedTime - $0 < 0.5 } ?? false
            if !justMissed {
                state.livesRemaining -= 1
                if state.livesRemaining <= 0 {
                    state.isGameOver = true
                }
            }
            return .noTarget
        }

        let target = state.fallingObjects[idx]

        // First hit on armored object — consume the hit, leave object on screen
        if !target.isVulnerable {
            state.fallingObjects[idx].hitsReceived += 1
            return .damaged(objectId: target.id)
        }

        // Destroying hit — remove object, award score and combo
        state.fallingObjects.remove(at: idx)

        state.comboCount += 1
        let newMultiplier: CGFloat
        switch state.comboCount {
        case ..<5:  newMultiplier = 1.0
        case ..<10: newMultiplier = 1.5
        case ..<15: newMultiplier = 2.0
        default:    newMultiplier = 2.5
        }
        state.comboMultiplier = newMultiplier

        state.score += scoreForHit(normalizedY: target.normalizedY)
        state.hits += 1
        return .hit(objectId: target.id, normalizedY: target.normalizedY, lane: target.lane, symbol: target.symbol)
    }

    // MARK: - Reset

    /// Reset engine for a fresh attempt at the same level.
    func reset() {
        state = EngineState()
        spawnScheduler.reset()
    }

    /// Restores 1 life — used by the rewarded continue mechanic. Capped at initial lives (3).
    func restoreLife() {
        state.livesRemaining = min(state.livesRemaining + 1, 3)
        state.isGameOver = false
    }

    // MARK: - Private Helpers

    /// Bonus scoring: earlier hits (lower normalizedY) earn more points.
    /// Base: 100pts. Bonus: up to 100pts extra when hit near top.
    /// Multiplied by current combo multiplier.
    private func scoreForHit(normalizedY: CGFloat) -> Int {
        let base = 100
        let bonus = Int(100.0 * max(0, 1.0 - normalizedY))
        return Int(CGFloat(base + bonus) * state.comboMultiplier)
    }

    /// Resolve the speed multiplier for a given elapsed time.
    /// Returns the multiplier of the last applicable phase.
    private func resolvedSpeedMultiplier(elapsed: TimeInterval) -> CGFloat {
        let applicable = config.speedPhases.filter { $0.startsAtSeconds <= elapsed }
        return applicable.last?.speedMultiplier ?? 1.0
    }
}
