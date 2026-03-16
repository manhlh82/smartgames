import Foundation

/// Generates all 50 Drop Rush level configurations via interpolation.
/// To tune difficulty: change the 5 TierDefinition structs below, not individual levels.
enum LevelDefinitions {

    // MARK: - Public API

    /// All 50 levels, lazily generated once.
    static let levels: [LevelConfig] = generateLevels()

    /// Convenience accessor (1-based index).
    static func level(_ number: Int) -> LevelConfig? {
        guard (1...50).contains(number) else { return nil }
        return levels[number - 1]
    }

    // MARK: - Tier Definitions

    /// Parameters at the start and end of each difficulty tier.
    private struct TierDefinition {
        let levelRange: ClosedRange<Int>
        let startSpeed: CGFloat
        let endSpeed: CGFloat
        let startInterval: TimeInterval
        let endInterval: TimeInterval
        let startMaxOnScreen: Int
        let endMaxOnScreen: Int
        let startTotalObjects: Int
        let endTotalObjects: Int
        let speedPhases: [SpeedPhase]
        /// Probability [0.0–1.0] that any spawned object is armored (requires 2 taps).
        let armoredProbability: CGFloat
    }

    // All tiers target exactly 30 seconds: duration = totalObjects × spawnInterval.
    // One object per interval (no burst). Density scales: L1=15 obj/30s → L50=60 obj/30s.
    // Speed phases: 1× → 2× at 10s → 4× at 20s (all tiers).
    private static let tiers: [TierDefinition] = [
        // Tier 1: Tutorial (1–5) — no armored objects
        // L1: 15 obj × 2.0s = 30s | L5: 20 obj × 1.5s = 30s
        TierDefinition(levelRange: 1...5,
                       startSpeed: 0.05, endSpeed: 0.07,
                       startInterval: 2.0, endInterval: 1.5,
                       startMaxOnScreen: 2, endMaxOnScreen: 3,
                       startTotalObjects: 15, endTotalObjects: 20,
                       speedPhases: SpeedPhase.doubling,
                       armoredProbability: 0.0),
        // Tier 2: Easy (6–15) — no armored objects
        // L6: 20 obj × 1.5s = 30s | L15: 30 obj × 1.0s = 30s
        TierDefinition(levelRange: 6...15,
                       startSpeed: 0.07, endSpeed: 0.09,
                       startInterval: 1.5, endInterval: 1.0,
                       startMaxOnScreen: 3, endMaxOnScreen: 4,
                       startTotalObjects: 20, endTotalObjects: 30,
                       speedPhases: SpeedPhase.doubling,
                       armoredProbability: 0.0),
        // Tier 3: Medium (16–30) — 10% armored
        // L16: 30 obj × 1.0s = 30s | L30: 45 obj × 0.67s = 30s
        TierDefinition(levelRange: 16...30,
                       startSpeed: 0.09, endSpeed: 0.12,
                       startInterval: 1.0, endInterval: 0.67,
                       startMaxOnScreen: 4, endMaxOnScreen: 5,
                       startTotalObjects: 30, endTotalObjects: 45,
                       speedPhases: SpeedPhase.doubling,
                       armoredProbability: 0.10),
        // Tier 4: Hard (31–40) — 20% armored
        // L31: 45 obj × 0.67s = 30s | L40: 55 obj × 0.55s = 30s
        TierDefinition(levelRange: 31...40,
                       startSpeed: 0.12, endSpeed: 0.15,
                       startInterval: 0.67, endInterval: 0.55,
                       startMaxOnScreen: 5, endMaxOnScreen: 7,
                       startTotalObjects: 45, endTotalObjects: 55,
                       speedPhases: SpeedPhase.doubling,
                       armoredProbability: 0.20),
        // Tier 5: Expert (41–50) — 30% armored
        // L41: 55 obj × 0.55s = 30s | L50: 60 obj × 0.5s = 30s
        TierDefinition(levelRange: 41...50,
                       startSpeed: 0.15, endSpeed: 0.18,
                       startInterval: 0.55, endInterval: 0.50,
                       startMaxOnScreen: 6, endMaxOnScreen: 8,
                       startTotalObjects: 55, endTotalObjects: 60,
                       speedPhases: SpeedPhase.doubling,
                       armoredProbability: 0.30),
    ]

    // MARK: - Generation

    private static func generateLevels() -> [LevelConfig] {
        (1...50).map { level in
            guard let tier = tiers.first(where: { $0.levelRange.contains(level) }) else {
                fatalError("No tier defined for level \(level)")
            }
            let t = tierProgress(level: level, tier: tier)
            return LevelConfig(
                levelNumber: level,
                symbolPool: symbolsForLevel(level),
                baseSpeed: lerp(tier.startSpeed, tier.endSpeed, t),
                spawnInterval: lerp(tier.startInterval, tier.endInterval, t),
                maxOnScreen: lerpInt(tier.startMaxOnScreen, tier.endMaxOnScreen, t),
                totalObjects: lerpInt(tier.startTotalObjects, tier.endTotalObjects, t),
                speedPhases: tier.speedPhases,
                laneCount: laneCountForLevel(level),
                armoredProbability: tier.armoredProbability
            )
        }
    }

    // MARK: - Symbol Progression

    /// Symbol pool expands as levels increase.
    private static func symbolsForLevel(_ level: Int) -> [String] {
        switch level {
        case 1...2:  return ["1","2"]
        case 3...9:  return ["1","2","3"]
        case 10...19: return ["1","2","3","4"]
        case 20...24: return ["1","2","3","4","5"]
        case 25...34: return ["1","2","3","4","5","6"]
        case 35...44: return ["1","2","3","4","5","6","7"]
        case 45...47: return ["1","2","3","4","5","6","7","8"]
        default:      return ["1","2","3","4","5","6","7","8","9"]
        }
    }

    // MARK: - Lane Count

    private static func laneCountForLevel(_ level: Int) -> Int {
        switch level {
        case 1...5:   return 3
        case 6...30:  return 4
        default:      return 5
        }
    }

    // MARK: - Helpers

    /// Normalized progress within a tier (0.0 at start, 1.0 at end).
    private static func tierProgress(level: Int, tier: TierDefinition) -> CGFloat {
        let range = tier.levelRange
        guard range.count > 1 else { return 0 }
        return CGFloat(level - range.lowerBound) / CGFloat(range.count - 1)
    }

    /// Linear interpolation for CGFloat.
    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    /// Linear interpolation for Double.
    private static func lerp(_ a: TimeInterval, _ b: TimeInterval, _ t: CGFloat) -> TimeInterval {
        a + (b - a) * Double(t)
    }

    /// Linear interpolation for Int (rounded).
    private static func lerpInt(_ a: Int, _ b: Int, _ t: CGFloat) -> Int {
        Int((CGFloat(a) + CGFloat(b - a) * t).rounded())
    }
}
