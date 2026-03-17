import Foundation

// MARK: - Tier

/// Identifies which top-percentage tier a player falls into.
enum WeeklyRewardTier: String, Codable {
    case top1, top5, top25, top50, participation
}

// MARK: - State

/// Persisted weekly state — one per week.
struct WeeklyChallengeState: Codable {
    /// ISO week identifier e.g. "2026-W12"
    var weekIdentifier: String
    /// Best score per game this week (game ID -> score)
    var bestScores: [String: Int]
    /// Whether rewards for the previous week have been claimed
    var rewardsClaimed: Bool

    init(weekIdentifier: String) {
        self.weekIdentifier = weekIdentifier
        self.bestScores = [:]
        self.rewardsClaimed = false
    }
}

// MARK: - Result

/// Reward result for a single game after weekly leaderboard resolution.
struct WeeklyGameReward {
    let game: String
    let tier: WeeklyRewardTier
    let gold: Int
    let diamonds: Int
}

/// Aggregate reward result shown in the result popup.
struct WeeklyRewardResult {
    let gameRewards: [WeeklyGameReward]
}
