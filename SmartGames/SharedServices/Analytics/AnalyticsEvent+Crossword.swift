import Foundation

extension AnalyticsEvent {
    static func crosswordStarted(difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("crossword_started", ["difficulty": difficulty])
    }
    static func crosswordCompleted(difficulty: String, hintsUsed: Int, timeSeconds: Int) -> AnalyticsEvent {
        AnalyticsEvent("crossword_completed", [
            "difficulty": difficulty,
            "hints_used": hintsUsed,
            "time_seconds": timeSeconds
        ])
    }
    static func crosswordAbandoned(difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("crossword_abandoned", ["difficulty": difficulty])
    }
    static func crosswordHintUsed(type: String, difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("crossword_hint_used", ["type": type, "difficulty": difficulty])
    }
    static func crosswordUndoUsed(difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("crossword_undo_used", ["difficulty": difficulty])
    }
    static func crosswordDiamondHintUsed(difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("crossword_diamond_hint_used", ["difficulty": difficulty])
    }
}
