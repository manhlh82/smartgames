import Foundation

/// Persisted player progress across all Drop Rush levels.
/// Keyed by level number (1-based). Saved under `dropRush.progress`.
struct DropRushProgress: Codable {
    /// Best star count per level (1–3). Missing key = never completed.
    var levelStars: [Int: Int] = [:]
    /// Best score per level.
    var levelHighScores: [Int: Int] = [:]
    /// Sum of all per-level high scores — used for Game Center leaderboard.
    var cumulativeHighScore: Int = 0

    // MARK: - Queries

    func starsForLevel(_ level: Int) -> Int {
        levelStars[level] ?? 0
    }

    /// Level 1 always unlocked; level N requires at least 1 star on level N-1.
    func isUnlocked(_ level: Int) -> Bool {
        level == 1 || starsForLevel(level - 1) >= 1
    }

    var totalStars: Int {
        levelStars.values.reduce(0, +)
    }

    // MARK: - Updates

    /// Record a level result; only improves existing records, never downgrades.
    mutating func recordResult(level: Int, stars: Int, score: Int) {
        let previousStars = levelStars[level] ?? 0
        let previousScore = levelHighScores[level] ?? 0

        if stars > previousStars {
            levelStars[level] = stars
        }
        if score > previousScore {
            cumulativeHighScore += score - previousScore
            levelHighScores[level] = score
        }
    }
}

// MARK: - Star Calculation

/// Calculate star rating from a level attempt's accuracy.
/// Accuracy = hits / (hits + misses); wrong taps don't affect accuracy.
func starsForAccuracy(hits: Int, misses: Int) -> Int {
    let total = hits + misses
    guard total > 0 else { return 0 }
    let accuracy = Double(hits) / Double(total)
    switch accuracy {
    case 0.95...: return 3
    case 0.80...: return 2
    case 0.60...: return 1
    default:      return 0
    }
}
