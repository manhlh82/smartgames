import Foundation

/// Persisted progress for Stack 2048 — high score, games played, best tile reached.
struct Stack2048Progress: Codable {
    var highScore: Int = 0
    var gamesPlayed: Int = 0
    var bestTile: Int = 0

    mutating func recordResult(score: Int, maxTile: Int) {
        gamesPlayed += 1
        if score > highScore { highScore = score }
        if maxTile > bestTile { bestTile = maxTile }
    }
}
