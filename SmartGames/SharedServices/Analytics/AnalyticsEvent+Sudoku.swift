import Foundation

/// Sudoku gameplay analytics events.
extension AnalyticsEvent {

    static let sudokuLobbyViewed = AnalyticsEvent("sudoku_lobby_viewed")

    static func sudokuGameStarted(difficulty: String, isResume: Bool) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_game_started", [
            "difficulty": difficulty,
            "is_resume": isResume
        ])
    }

    static func sudokuGamePaused(difficulty: String, elapsedSeconds: Int) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_game_paused", [
            "difficulty": difficulty,
            "elapsed_seconds": elapsedSeconds
        ])
    }

    static func sudokuGameResumed(difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_game_resumed", ["difficulty": difficulty])
    }

    static func sudokuGameAbandoned(difficulty: String, elapsedSeconds: Int, completionPct: Int) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_game_abandoned", [
            "difficulty": difficulty,
            "elapsed_seconds": elapsedSeconds,
            "completion_pct": completionPct
        ])
    }

    static func sudokuGameCompleted(difficulty: String, elapsedSeconds: Int,
                                    mistakes: Int, hintsUsed: Int, stars: Int) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_game_completed", [
            "difficulty": difficulty,
            "elapsed_seconds": elapsedSeconds,
            "mistakes": mistakes,
            "hints_used": hintsUsed,
            "stars": stars
        ])
    }

    static func sudokuGameFailed(difficulty: String, elapsedSeconds: Int, mistakes: Int) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_game_failed", [
            "difficulty": difficulty,
            "elapsed_seconds": elapsedSeconds,
            "mistakes": mistakes
        ])
    }

    static func sudokuGameRestarted(difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_game_restarted", ["difficulty": difficulty])
    }

    static func sudokuNumberPlaced(difficulty: String, isCorrect: Bool, elapsedSeconds: Int) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_number_placed", [
            "difficulty": difficulty,
            "is_correct": isCorrect,
            "elapsed_seconds": elapsedSeconds
        ])
    }

    static func sudokuUndoUsed(difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_undo_used", ["difficulty": difficulty])
    }

    static func sudokuEraserUsed(difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_eraser_used", ["difficulty": difficulty])
    }

    static func sudokuPencilModeToggled(enabled: Bool) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_pencil_mode_toggled", ["enabled": enabled])
    }

    static func sudokuHintUsed(difficulty: String, hintsRemainingBefore: Int) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_hint_used", [
            "difficulty": difficulty,
            "hints_remaining_before": hintsRemainingBefore
        ])
    }

    static func sudokuHintExhausted(difficulty: String) -> AnalyticsEvent {
        AnalyticsEvent("sudoku_hint_exhausted", ["difficulty": difficulty])
    }
}
