import Foundation

/// Defines a single curated challenge level for Stack 2048.
struct Stack2048ChallengeLevel {
    let level: Int
    /// Win condition: reach a tile of this value.
    let targetTile: Int
    /// Optional score-based win condition (nil = tile-based only).
    let targetScore: Int?
    /// Max moves allowed (nil = unlimited).
    let moveLimit: Int?
    /// Pre-placed tiles at game start: (column 0-4, value).
    let initialTiles: [(col: Int, value: Int)]
    /// Complete within this many moves for 2-star rating.
    let twoStarMoves: Int
    /// Complete within this many moves for 3-star rating.
    let threeStarMoves: Int

    /// Calculate star rating based on moves used.
    /// 3-star: within threeStarMoves, 2-star: within twoStarMoves, 1-star: completed.
    func stars(movesUsed: Int) -> Int {
        if movesUsed <= threeStarMoves { return 3 }
        if movesUsed <= twoStarMoves   { return 2 }
        return 1
    }
}
