import Foundation

/// Completion record for a single day's Drop Rush daily challenge.
struct DropRushDailyChallengeState: Codable, Equatable {
    /// UTC date string e.g. "2026-03-11"
    let dateString: String
    var isCompleted: Bool
    var score: Int?
    var stars: Int?
}

/// Persisted streak data for Drop Rush daily challenges.
struct DropRushDailyStreakData: Codable {
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    /// UTC date string of the last completed day.
    var lastCompletedDate: String?
}
