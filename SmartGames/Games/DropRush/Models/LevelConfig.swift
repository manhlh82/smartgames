import Foundation

/// Time-based speed ramp within a level.
/// Engine applies the highest applicable phase multiplier at any point in time.
struct SpeedPhase {
    /// Elapsed game time (seconds) at which this multiplier kicks in.
    let startsAtSeconds: TimeInterval
    /// Multiplier applied to all object speeds (e.g. 1.4 = 40% faster).
    let speedMultiplier: CGFloat

    /// Standard three-phase ramp used by most levels.
    static let standard: [SpeedPhase] = [
        SpeedPhase(startsAtSeconds: 0,  speedMultiplier: 1.0),
        SpeedPhase(startsAtSeconds: 10, speedMultiplier: 1.4),
        SpeedPhase(startsAtSeconds: 20, speedMultiplier: 1.8),
    ]

    /// Universal ramp: doubles speed every 10 seconds.
    /// 0s → 1x, 10s → 2x, 20s → 4x
    static let doubling: [SpeedPhase] = [
        SpeedPhase(startsAtSeconds: 0,  speedMultiplier: 1.0),
        SpeedPhase(startsAtSeconds: 10, speedMultiplier: 2.0),
        SpeedPhase(startsAtSeconds: 20, speedMultiplier: 4.0),
    ]
}

// MARK: - Tier-Specific Speed Phase Presets

extension SpeedPhase {
    /// Gentle ramp — used by Tutorial levels 1–5.
    static let tutorial: [SpeedPhase] = [
        SpeedPhase(startsAtSeconds: 0,  speedMultiplier: 1.0),
        SpeedPhase(startsAtSeconds: 15, speedMultiplier: 1.15),
        SpeedPhase(startsAtSeconds: 30, speedMultiplier: 1.3),
    ]
    /// Moderate ramp — used by Easy levels 6–15.
    static let easy: [SpeedPhase] = [
        SpeedPhase(startsAtSeconds: 0,  speedMultiplier: 1.0),
        SpeedPhase(startsAtSeconds: 12, speedMultiplier: 1.25),
        SpeedPhase(startsAtSeconds: 24, speedMultiplier: 1.5),
    ]
    /// Steeper ramp — used by Medium levels 16–30.
    static let medium: [SpeedPhase] = [
        SpeedPhase(startsAtSeconds: 0,  speedMultiplier: 1.0),
        SpeedPhase(startsAtSeconds: 10, speedMultiplier: 1.3),
        SpeedPhase(startsAtSeconds: 20, speedMultiplier: 1.6),
    ]
    /// Aggressive ramp — used by Hard and Expert levels 31–50.
    static let hard: [SpeedPhase] = [
        SpeedPhase(startsAtSeconds: 0,  speedMultiplier: 1.0),
        SpeedPhase(startsAtSeconds: 8,  speedMultiplier: 1.4),
        SpeedPhase(startsAtSeconds: 18, speedMultiplier: 1.8),
    ]
}

/// All parameters that define one level's gameplay.
/// Levels are authored as `LevelConfig` values; engine is config-driven.
struct LevelConfig {
    let levelNumber: Int
    /// Symbols that can appear in this level (e.g. ["1","2","3"]).
    let symbolPool: [String]
    /// Base fall speed in normalized units per second (before phase multiplier).
    let baseSpeed: CGFloat
    /// Seconds between consecutive spawns.
    let spawnInterval: TimeInterval
    /// Maximum simultaneous falling objects.
    let maxOnScreen: Int
    /// Total objects to spawn before level ends (level complete when all cleared).
    let totalObjects: Int
    /// Time-based speed phases; sorted ascending by startsAtSeconds.
    let speedPhases: [SpeedPhase]
    /// Number of horizontal lanes (buttons in input bar = symbolPool.count).
    let laneCount: Int
    /// Probability [0.0–1.0] that any spawned object is armored (requires 2 taps).
    let armoredProbability: CGFloat

    /// Derive lane count from symbol pool size by default.
    init(
        levelNumber: Int,
        symbolPool: [String],
        baseSpeed: CGFloat,
        spawnInterval: TimeInterval,
        maxOnScreen: Int,
        totalObjects: Int,
        speedPhases: [SpeedPhase] = SpeedPhase.standard,
        laneCount: Int? = nil,
        armoredProbability: CGFloat = 0.0
    ) {
        self.levelNumber = levelNumber
        self.symbolPool = symbolPool
        self.baseSpeed = baseSpeed
        self.spawnInterval = spawnInterval
        self.maxOnScreen = maxOnScreen
        self.totalObjects = totalObjects
        self.speedPhases = speedPhases
        self.laneCount = laneCount ?? symbolPool.count
        self.armoredProbability = armoredProbability
    }
}
