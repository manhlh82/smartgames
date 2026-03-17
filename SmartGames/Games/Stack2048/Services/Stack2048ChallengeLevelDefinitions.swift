import Foundation

/// Static catalog of 50 curated Stack 2048 challenge levels.
/// Formula-based generation grouped into 4 difficulty tiers.
enum Stack2048ChallengeLevelDefinitions {

    // MARK: - Public API

    /// Returns the level definition for level number 1–50, or nil if out of range.
    static func level(_ n: Int) -> Stack2048ChallengeLevel? {
        guard n >= 1, n <= all.count else { return nil }
        return all[n - 1]
    }

    // MARK: - Full Catalog

    static let all: [Stack2048ChallengeLevel] = {
        var levels: [Stack2048ChallengeLevel] = []

        // Tier 1: Levels 1–10 — targetTile 64
        for i in 1...10 {
            let initialTiles = initialTilesForTier1(level: i)
            levels.append(Stack2048ChallengeLevel(
                level: i,
                targetTile: 64,
                targetScore: nil,
                moveLimit: nil,
                initialTiles: initialTiles,
                twoStarMoves: 30,
                threeStarMoves: 20
            ))
        }

        // Tier 2: Levels 11–25 — targetTile 128
        for i in 11...25 {
            let initialTiles = initialTilesForTier2(level: i)
            levels.append(Stack2048ChallengeLevel(
                level: i,
                targetTile: 128,
                targetScore: nil,
                moveLimit: nil,
                initialTiles: initialTiles,
                twoStarMoves: 40,
                threeStarMoves: 25
            ))
        }

        // Tier 3: Levels 26–40 — targetTile 256
        for i in 26...40 {
            let initialTiles = initialTilesForTier3(level: i)
            levels.append(Stack2048ChallengeLevel(
                level: i,
                targetTile: 256,
                targetScore: nil,
                moveLimit: nil,
                initialTiles: initialTiles,
                twoStarMoves: 50,
                threeStarMoves: 30
            ))
        }

        // Tier 4: Levels 41–50 — targetTile 512
        for i in 41...50 {
            let initialTiles = initialTilesForTier4(level: i)
            levels.append(Stack2048ChallengeLevel(
                level: i,
                targetTile: 512,
                targetScore: nil,
                moveLimit: nil,
                initialTiles: initialTiles,
                twoStarMoves: 60,
                threeStarMoves: 35
            ))
        }

        return levels
    }()

    // MARK: - Initial Tile Generators

    /// Tier 1 (1–10): 1 tile of value 2 in varying columns.
    private static func initialTilesForTier1(level: Int) -> [(col: Int, value: Int)] {
        let col = (level - 1) % 5
        return [(col: col, value: 2)]
    }

    /// Tier 2 (11–25): 2 tiles — one value 2, one value 4.
    private static func initialTilesForTier2(level: Int) -> [(col: Int, value: Int)] {
        let offset = level - 11
        let col1 = offset % 5
        let col2 = (offset + 2) % 5
        return [(col: col1, value: 2), (col: col2, value: 4)]
    }

    /// Tier 3 (26–40): 2 tiles — value 4 and value 8.
    private static func initialTilesForTier3(level: Int) -> [(col: Int, value: Int)] {
        let offset = level - 26
        let col1 = offset % 5
        let col2 = (offset + 3) % 5
        return [(col: col1, value: 4), (col: col2, value: 8)]
    }

    /// Tier 4 (41–50): 3 tiles — values 4, 8, 16.
    private static func initialTilesForTier4(level: Int) -> [(col: Int, value: Int)] {
        let offset = level - 41
        let col1 = offset % 5
        let col2 = (offset + 1) % 5
        let col3 = (offset + 3) % 5
        return [(col: col1, value: 4), (col: col2, value: 8), (col: col3, value: 16)]
    }
}
