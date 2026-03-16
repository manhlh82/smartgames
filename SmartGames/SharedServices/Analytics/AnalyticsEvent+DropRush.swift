import Foundation

/// Drop Rush analytics events.
extension AnalyticsEvent {

    static func dropRushLevelStarted(level: Int) -> AnalyticsEvent {
        AnalyticsEvent("drop_rush_level_started", ["level": level])
    }

    static func dropRushLevelCompleted(level: Int, score: Int, stars: Int, accuracy: Double) -> AnalyticsEvent {
        AnalyticsEvent("drop_rush_level_completed", [
            "level": level, "score": score,
            "stars": stars, "accuracy": Int(accuracy * 100)
        ])
    }

    static func dropRushLevelFailed(level: Int, score: Int, misses: Int) -> AnalyticsEvent {
        AnalyticsEvent("drop_rush_level_failed", [
            "level": level, "score": score, "misses": misses
        ])
    }

    static func dropRushPaused(level: Int, elapsed: TimeInterval) -> AnalyticsEvent {
        AnalyticsEvent("drop_rush_paused", [
            "level": level, "elapsed_seconds": Int(elapsed)
        ])
    }

    static func dropRushQuit(level: Int, elapsed: TimeInterval) -> AnalyticsEvent {
        AnalyticsEvent("drop_rush_quit", [
            "level": level, "elapsed_seconds": Int(elapsed)
        ])
    }

    static func dropRushContinueUsed(level: Int) -> AnalyticsEvent {
        AnalyticsEvent("drop_rush_continue_used", ["level": level])
    }

    static func dropRushContinueDeclined(level: Int) -> AnalyticsEvent {
        AnalyticsEvent("drop_rush_continue_declined", ["level": level])
    }
}
