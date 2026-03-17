import Foundation

/// Completion record for a single day's Stack 2048 daily challenge.
struct Stack2048DailyChallengeState: Codable, Equatable {
    /// UTC date string e.g. "2026-03-11"
    let dateString: String
    var isCompleted: Bool
    var score: Int?
}

/// Persisted streak data for Stack 2048 daily challenges.
struct Stack2048DailyStreakData: Codable {
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    /// UTC date string of the last completed day.
    var lastCompletedDate: String?
}
