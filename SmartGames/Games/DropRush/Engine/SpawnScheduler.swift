import Foundation

/// Decides when and what to spawn next.
/// Stateful — tracks spawn timing and lane history to prevent clustering.
/// One object per interval: duration ≈ totalObjects × spawnInterval.
struct SpawnScheduler {
    private var lastSpawnTime: TimeInterval = -1  // -1 forces immediate first spawn
    private var lastLane: Int? = nil

    /// Attempt to spawn one object. Returns empty array when conditions are not met.
    /// Conditions: interval elapsed, screen not at cap, total not exhausted.
    mutating func trySpawn(
        elapsed: TimeInterval,
        config: LevelConfig,
        objectsSpawned: Int,
        onScreenCount: Int
    ) -> [FallingObject] {
        guard objectsSpawned < config.totalObjects else { return [] }
        guard onScreenCount < config.maxOnScreen else { return [] }
        guard elapsed - lastSpawnTime >= config.spawnInterval else { return [] }

        lastSpawnTime = elapsed
        return [makeObject(config: config)]
    }

    /// Pick a lane, avoiding the most recently used one to reduce clustering.
    private mutating func pickLane(laneCount: Int) -> Int {
        guard laneCount > 1 else { lastLane = 0; return 0 }
        var available = Array(0..<laneCount)
        if let last = lastLane {
            available.removeAll { $0 == last }
        }
        let lane = available.randomElement() ?? Int.random(in: 0..<laneCount)
        lastLane = lane
        return lane
    }

    /// Build a single FallingObject from config.
    /// When armoredProbability > 0, randomly assigns hitsRequired = 2 to create armored objects.
    private mutating func makeObject(config: LevelConfig) -> FallingObject {
        let symbol = config.symbolPool.randomElement() ?? "1"
        let lane = pickLane(laneCount: config.laneCount)
        let isArmored = config.armoredProbability > 0 && CGFloat.random(in: 0..<1) < config.armoredProbability
        return FallingObject(symbol: symbol, lane: lane, speed: config.baseSpeed, hitsRequired: isArmored ? 2 : 1)
    }

    /// Reset for a new level.
    mutating func reset() {
        lastSpawnTime = -1
        lastLane = nil
    }
}
