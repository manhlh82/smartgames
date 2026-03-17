import Foundation

/// Persisted progress for Stack 2048 — high score, games played, best tile reached, wins, challenge stars.
struct Stack2048Progress: Codable {
    var highScore: Int = 0
    var gamesPlayed: Int = 0
    var bestTile: Int = 0
    var wins: Int = 0
    /// Best star rating per challenge level. Key = level number (1-50).
    var challengeStars: [Int: Int] = [:]

    mutating func recordResult(score: Int, maxTile: Int) {
        gamesPlayed += 1
        if score > highScore { highScore = score }
        if maxTile > bestTile { bestTile = maxTile }
    }

    mutating func recordWin() { wins += 1 }

    /// Save challenge star result — only updates if new stars is higher.
    mutating func recordChallengeResult(level: Int, stars: Int) {
        let existing = challengeStars[level] ?? 0
        if stars > existing { challengeStars[level] = stars }
    }
}
