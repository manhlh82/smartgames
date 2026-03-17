import Foundation

/// Stack 2048 analytics events.
extension AnalyticsEvent {

    static func stack2048GameStarted() -> AnalyticsEvent {
        AnalyticsEvent("stack2048_game_started", [:])
    }

    static func stack2048GameOver(score: Int, maxTile: Int, gamesPlayed: Int) -> AnalyticsEvent {
        AnalyticsEvent("stack2048_game_over", [
            "score": score,
            "max_tile": maxTile,
            "games_played": gamesPlayed
        ])
    }

    static func stack2048MilestoneTile(value: Int) -> AnalyticsEvent {
        AnalyticsEvent("stack2048_milestone_tile", ["value": value])
    }

    static func stack2048PowerUpUsed(type: String, goldSpent: Int) -> AnalyticsEvent {
        AnalyticsEvent("stack2048_power_up_used", [
            "type": type,
            "gold_spent": goldSpent
        ])
    }

    static func stack2048Paused(score: Int) -> AnalyticsEvent {
        AnalyticsEvent("stack2048_paused", ["score": score])
    }

    static func stack2048Quit(score: Int) -> AnalyticsEvent {
        AnalyticsEvent("stack2048_quit", ["score": score])
    }

    static func stack2048Win(score: Int) -> AnalyticsEvent {
        AnalyticsEvent("stack2048_win", ["score": score])
    }
}
