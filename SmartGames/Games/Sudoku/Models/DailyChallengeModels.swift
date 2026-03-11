import Foundation

/// Completion record for a single day's daily challenge.
struct DailyChallengeState: Codable, Equatable {
    /// UTC date string e.g. "2026-03-11"
    let dateString: String
    var isCompleted: Bool
    var elapsedSeconds: Int?
    var mistakes: Int?
    var stars: Int?
}

/// Persisted streak data across all days.
struct DailyStreakData: Codable {
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    /// UTC date string of the last completed day, e.g. "2026-03-10"
    var lastCompletedDate: String?
    /// All UTC date strings on which the user completed the daily challenge
    var completedDates: Set<String> = []
}
