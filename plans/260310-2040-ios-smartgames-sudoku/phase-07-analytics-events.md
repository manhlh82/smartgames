# Phase 07 — Analytics Events

**Priority:** Medium | **Effort:** S | **PR:** PR-09

---

## Overview

Replace AnalyticsService stub with a real provider. Design event schema covering gameplay, monetization, and retention signals. Events are the foundation for future A/B testing and monetization optimization.

---

## PR-09 Goal

Real analytics integration (Firebase Analytics recommended — free tier, iOS-native, integrates with AdMob for LTV tracking). Implement all events listed below.

---

## Provider Recommendation

**Firebase Analytics** (primary)
- Free, no event limits for standard events
- Native iOS SDK, SwiftUI friendly
- Integrates with AdMob → ARPU / LTV tracking in one dashboard
- Audience segmentation for future push notifications

Alternative: Amplitude (better funnel analysis, free up to 10M events/mo). Can dual-log if needed.

**Setup:** Add `FirebaseAnalytics` via SPM. Initialize in `SmartGamesApp.swift` via `FirebaseApp.configure()`.

---

## AnalyticsService (Full Implementation)

```swift
// AnalyticsService.swift
import FirebaseAnalytics

final class AnalyticsService: ObservableObject, AnalyticsServiceProtocol {
    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters as? [String: Any])
        #if DEBUG
        print("[Analytics] \(event.name) — \(event.parameters)")
        #endif
    }
}
```

---

## Event Schema

All events follow snake_case naming. Parameters are consistent across events for easy funnel building.

### App Lifecycle

| Event | Parameters | Purpose |
|-------|-----------|---------|
| `app_open` | `session_id`, `is_returning_user` | DAU tracking |
| `att_permission_shown` | — | ATT funnel |
| `att_permission_response` | `status: authorized/denied/restricted` | ATT consent rate |

---

### Hub / Navigation

| Event | Parameters | Purpose |
|-------|-----------|---------|
| `hub_viewed` | — | Entry point tracking |
| `game_selected` | `game_id: sudoku` | Which games attract clicks |
| `settings_opened` | — | Settings engagement |

---

### Sudoku — Session

| Event | Parameters | Purpose |
|-------|-----------|---------|
| `sudoku_lobby_viewed` | — | Funnel: hub → lobby |
| `sudoku_game_started` | `difficulty`, `is_resume` | Game start rate per difficulty |
| `sudoku_game_paused` | `elapsed_seconds`, `difficulty` | When players pause |
| `sudoku_game_resumed` | `difficulty` | Resume rate |
| `sudoku_game_abandoned` | `elapsed_seconds`, `difficulty`, `completion_pct` | Drop-off analysis |
| `sudoku_game_completed` | `difficulty`, `elapsed_seconds`, `mistakes`, `hints_used`, `stars` | Core retention metric |
| `sudoku_game_failed` | `difficulty`, `elapsed_seconds`, `mistakes` | Difficulty calibration |
| `sudoku_game_restarted` | `difficulty` | Restart rate |

`completion_pct` = filled cells / empty cells × 100 (estimated progress at abandonment).

---

### Sudoku — Gameplay Interactions

| Event | Parameters | Purpose |
|-------|-----------|---------|
| `sudoku_number_placed` | `difficulty`, `is_correct`, `elapsed_seconds` | Error rate tracking |
| `sudoku_undo_used` | `difficulty` | Undo adoption |
| `sudoku_eraser_used` | `difficulty` | Eraser adoption |
| `sudoku_pencil_mode_toggled` | `enabled: bool` | Pencil mode adoption |
| `sudoku_hint_used` | `difficulty`, `hints_remaining_before` | Hint usage pattern |
| `sudoku_hint_exhausted` | `difficulty` | Monetization trigger point |

---

### Monetization

| Event | Parameters | Purpose |
|-------|-----------|---------|
| `ad_rewarded_prompt_shown` | `reason: hints/continue`, `difficulty` | Prompt conversion funnel |
| `ad_rewarded_accepted` | `reason: hints/continue` | Accept rate |
| `ad_rewarded_declined` | `reason: hints/continue` | Decline rate |
| `ad_rewarded_completed` | `reason: hints/continue` | Completion (reward granted) |
| `ad_rewarded_failed` | `reason`, `error_code` | Ad load failure rate |
| `ad_interstitial_shown` | — | Interstitial impression |
| `ad_interstitial_dismissed` | `watched_seconds` | Watch-through rate |

---

### Retention Signals

| Event | Parameters | Purpose |
|-------|-----------|---------|
| `daily_streak_shown` | `streak_days` | Phase 2 — Daily challenge |
| `sudoku_difficulty_upgraded` | `from`, `to` | Skill progression |

---

## Event Helper Extensions

```swift
// AnalyticsEvent+Sudoku.swift
extension AnalyticsEvent {
    static func sudokuGameStarted(difficulty: SudokuDifficulty, isResume: Bool) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "sudoku_game_started",
            parameters: ["difficulty": difficulty.rawValue, "is_resume": isResume]
        )
    }

    static func sudokuGameCompleted(
        difficulty: SudokuDifficulty,
        elapsedSeconds: Int,
        mistakes: Int,
        hintsUsed: Int,
        stars: Int
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "sudoku_game_completed",
            parameters: [
                "difficulty": difficulty.rawValue,
                "elapsed_seconds": elapsedSeconds,
                "mistakes": mistakes,
                "hints_used": hintsUsed,
                "stars": stars
            ]
        )
    }

    // ... one static factory per event for type safety
}
```

---

## Usage in ViewModel

```swift
// In SudokuGameViewModel
analytics.log(.sudokuGameStarted(difficulty: puzzle.difficulty, isResume: false))

// On win
analytics.log(.sudokuGameCompleted(
    difficulty: puzzle.difficulty,
    elapsedSeconds: elapsedSeconds,
    mistakes: mistakeCount,
    hintsUsed: hintsUsedThisGame,
    stars: starRating
))
```

---

## Key Dashboards to Build (Post-Launch)

1. **Retention funnel:** app_open → hub_viewed → game_started → game_completed
2. **Difficulty distribution:** which difficulties are played most
3. **Monetization funnel:** hint_exhausted → ad_prompt_shown → ad_accepted → ad_completed
4. **Error rate by difficulty:** sudoku_number_placed (is_correct=false) / total placements

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `SharedServices/Analytics/AnalyticsService.swift` | Replace stub |
| `SharedServices/Analytics/AnalyticsEvent.swift` | Extend with all events |
| `SharedServices/Analytics/AnalyticsEvent+Sudoku.swift` | Sudoku-specific factories |
| `Package.swift` | Add FirebaseAnalytics |
| `SmartGamesApp.swift` | Add FirebaseApp.configure() |
| `GoogleService-Info.plist` | Add (NOT committed to git — use CI secret) |

---

## Acceptance Criteria

- [ ] All listed events fire at correct moments (verified via Firebase DebugView)
- [ ] No PII in any event (no user IDs, no device identifiers beyond Firebase anonymous ID)
- [ ] `GoogleService-Info.plist` excluded from git via `.gitignore`
- [ ] Analytics compiles in both DEBUG and RELEASE

---

## Tests Needed

- `AnalyticsServiceTests` — mock logger, verify correct events fired on game start/complete/fail
- No network tests needed (Firebase SDK handles its own retry)

---

## Dependencies

- PR-07 (game lifecycle events exist to instrument)
- PR-08 (ad events to instrument)
