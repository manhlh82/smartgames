import Foundation

struct CrosswordDailyChallengeState: Codable, Equatable {
    let dateString: String
    var isCompleted: Bool
    var timeSeconds: Int?
    var hintsUsed: Int?
    var stars: Int?
}

struct CrosswordDailyStreakData: Codable {
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var lastCompletedDate: String?
}
