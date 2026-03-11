# Phase 3: Daily Challenge

## Context Links
- [SudokuGenerator.swift](../../SmartGames/Games/Sudoku/Engine/SudokuGenerator.swift)
- [SudokuLobbyView.swift](../../SmartGames/Games/Sudoku/Views/SudokuLobbyView.swift)
- [PersistenceService.swift](../../SmartGames/SharedServices/Persistence/PersistenceService.swift)
- [SudokuDifficulty.swift](../../SmartGames/Games/Sudoku/Models/SudokuDifficulty.swift)

## Overview
- **Priority:** P1 -- primary retention mechanic
- **Status:** ✅ Complete
- **Effort:** 8h
- **Description:** Date-seeded daily puzzle with streak tracking, completion badge, and optional push notification. No server required -- deterministic seeding ensures all users get the same puzzle per day.

## Key Insights
- `SudokuGenerator.generate()` uses `Array.shuffled()` internally -- need to inject a seeded `RandomNumberGenerator` to make output deterministic for a given date
- Difficulty can rotate: Mon=Easy, Tue=Medium, Wed=Hard, Thu=Expert, Fri=Hard, Sat=Medium, Sun=Easy (keeps it accessible)
- Streak = consecutive calendar days with completed daily puzzle
- Push notification: local `UNUserNotificationCenter`, scheduled daily at user's preferred time (default 9 AM)
- Existing `PuzzleBank` fetches pre-made puzzles -- daily challenge bypasses this, generates fresh via seeded generator

## Requirements

### Functional
- FR1: One unique puzzle per calendar day (UTC), same for all users
- FR2: Daily puzzle accessible from lobby via prominent "Daily Challenge" card
- FR3: Streak counter: consecutive days completed
- FR4: Completion state persisted -- revisiting shows "Completed" badge, stats, time
- FR5: Optional daily reminder push notification (configurable time in Settings)
- FR6: Difficulty rotates by day of week
- FR7: Calendar view showing completed days in current month (stretch)

### Non-Functional
- NFR1: Puzzle generation < 1s even on older devices (seeded generation is same speed)
- NFR2: Timezone: use UTC to avoid double-puzzle edge cases
- NFR3: Works fully offline

## Architecture

### Deterministic Puzzle Generation

Inject a `SeededRandomNumberGenerator` into `SudokuGenerator`:

```swift
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        // xorshift64 or similar fast PRNG
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
```

Seed derived from date: `"daily-\(yyyy-MM-dd)"` hashed to UInt64.

Modify `SudokuGenerator.generate()` to accept optional `RandomNumberGenerator` parameter. Default = `SystemRandomNumberGenerator`. For daily challenge, pass seeded one.

### Data Model

```swift
struct DailyChallengeState: Codable {
    let dateString: String            // "2026-03-11"
    var isCompleted: Bool
    var elapsedSeconds: Int?
    var mistakes: Int?
    var stars: Int?
}

struct DailyStreakData: Codable {
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var lastCompletedDate: String?     // "2026-03-10"
    var completedDates: Set<String>    // for calendar view
}
```

### DailyChallengeService

```swift
@MainActor
final class DailyChallengeService: ObservableObject {
    @Published var todayState: DailyChallengeState
    @Published var streak: DailyStreakData

    func todayPuzzle() -> SudokuPuzzle           // deterministic
    func todayDifficulty() -> SudokuDifficulty   // based on weekday
    func markCompleted(time:, mistakes:, stars:)
    func isCompletedToday() -> Bool

    // Notification management
    func scheduleReminderNotification(at hour: Int)
    func cancelReminderNotification()
}
```

### Day-of-Week Difficulty Map
| Day | Difficulty |
|-----|-----------|
| Mon | Easy |
| Tue | Medium |
| Wed | Hard |
| Thu | Expert |
| Fri | Hard |
| Sat | Medium |
| Sun | Easy |

## Files to Create

| File | Purpose |
|------|---------|
| `Games/Sudoku/Engine/SeededRandomNumberGenerator.swift` | Deterministic PRNG |
| `SharedServices/DailyChallenge/DailyChallengeService.swift` | Daily puzzle + streak logic |
| `Games/Sudoku/Views/DailyChallengeCardView.swift` | Lobby card showing today's challenge |
| `Games/Sudoku/Views/DailyChallengeCalendarView.swift` | Monthly calendar with completion dots |
| `Games/Sudoku/Models/DailyChallengeState.swift` | Data models |

## Files to Modify

| File | Change |
|------|--------|
| `Games/Sudoku/Engine/SudokuGenerator.swift` | Accept optional `RandomNumberGenerator` parameter; use `shuffled(using:)` instead of `shuffled()` |
| `Games/Sudoku/Views/SudokuLobbyView.swift` | Add DailyChallengeCardView above difficulty picker |
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Add `isDailyChallenge` flag; on win, notify DailyChallengeService |
| `Navigation/AppRoutes.swift` | Add `.sudokuDailyChallenge` route (or reuse `.sudokuGame` with flag) |
| `AppEnvironment.swift` | Add `DailyChallengeService` |
| `SmartGamesApp.swift` | Inject `DailyChallengeService`; check/refresh daily state on launch |
| `PersistenceService.swift` | Add keys: `sudoku.daily.state`, `sudoku.daily.streak` |
| `SharedServices/Settings/SettingsView.swift` | Add "Daily Reminder" toggle + time picker |
| `SharedServices/Settings/SettingsService.swift` | Add `isDailyReminderEnabled`, `dailyReminderHour` |

## Implementation Steps

1. **Create `SeededRandomNumberGenerator.swift`**
   - Implement xorshift64 PRNG conforming to `RandomNumberGenerator`
   - Add `static func seed(from dateString: String) -> UInt64` using stable hash

2. **Modify `SudokuGenerator.generate()`**
   - Add parameter: `using rng: inout some RandomNumberGenerator = SystemRandomNumberGenerator()`
   - Replace all `.shuffled()` calls with `.shuffled(using: &rng)`
   - This is backward-compatible -- existing callers get random behavior

3. **Create `DailyChallengeState.swift`**
   - `DailyChallengeState` and `DailyStreakData` structs

4. **Create `DailyChallengeService.swift`**
   - UTC-based date string: `DateFormatter` with `timeZone = .gmt`
   - `todayDifficulty()`: map `Calendar.current.component(.weekday)` to difficulty
   - `todayPuzzle()`: create seeded RNG from date, call `generator.generate(using:)`
   - `markCompleted()`: save state, update streak:
     - If `lastCompletedDate == yesterday` → increment streak
     - If `lastCompletedDate == today` → no-op
     - Else → reset streak to 1
     - Update `bestStreak` if `currentStreak > bestStreak`
   - Cache generated puzzle in memory to avoid regenerating on every access

5. **Add persistence keys**
   - `PersistenceService.Keys.sudokuDailyState = "sudoku.daily.state"`
   - `PersistenceService.Keys.sudokuDailyStreak = "sudoku.daily.streak"`

6. **Wire into `AppEnvironment`**
   - Add `let dailyChallenge: DailyChallengeService`

7. **Create `DailyChallengeCardView.swift`**
   - Shows: today's difficulty badge, streak count (flame icon), "Play" or "Completed" button
   - If completed: show time and stars, button says "Completed" (disabled or shows recap)
   - Tap starts daily challenge game

8. **Update `SudokuLobbyView`**
   - Insert `DailyChallengeCardView` between title and difficulty sheet
   - Pass `DailyChallengeService` from environment

9. **Update `SudokuGameViewModel`**
   - Add `isDailyChallenge: Bool` init parameter (default false)
   - On win, if `isDailyChallenge`: call `dailyChallengeService.markCompleted(...)`
   - Disable "Restart" for daily (you get one shot, or allow restart but keep best time)

10. **Create `DailyChallengeCalendarView.swift`** (stretch)
    - Simple month grid, dots on completed days
    - Accessible from daily challenge card

11. **Add notification support**
    - Request notification permission on first enable
    - Schedule repeating local notification at configured time
    - Add settings: `isDailyReminderEnabled`, `dailyReminderHour`

12. **Update `SettingsView`**
    - Add "Daily Reminder" toggle
    - Show time picker when enabled

## Todo List

- [ ] Create `SeededRandomNumberGenerator` with xorshift64
- [ ] Modify `SudokuGenerator` to accept generic RNG parameter
- [ ] Verify determinism: same date → same puzzle across runs
- [ ] Create `DailyChallengeState` and `DailyStreakData` models
- [ ] Create `DailyChallengeService` with streak logic
- [ ] Add persistence keys for daily state/streak
- [ ] Wire into `AppEnvironment` and `SmartGamesApp`
- [ ] Create `DailyChallengeCardView` for lobby
- [ ] Update `SudokuLobbyView` with daily challenge card
- [ ] Update `SudokuGameViewModel` with daily challenge flag
- [ ] Implement local push notification scheduling
- [ ] Add daily reminder settings to `SettingsView`
- [ ] Create `DailyChallengeCalendarView` (stretch)
- [ ] Test streak edge cases (timezone, skip day, same day replay)

## Acceptance Criteria

- [ ] Same date always produces same puzzle (deterministic)
- [ ] Different dates produce different puzzles
- [ ] Streak increments on consecutive day completions
- [ ] Streak resets after missing a day
- [ ] Completed daily shows badge/stats in lobby card
- [ ] Daily challenge persists across app kills (can resume)
- [ ] Push notification fires at configured time
- [ ] Works fully offline

## Tests Needed

- `SeededRandomNumberGenerator`: same seed → same sequence
- `SudokuGenerator` with seeded RNG: same seed → same puzzle
- `DailyChallengeService.todayDifficulty()`: verify day-of-week mapping
- Streak logic:
  - Day 1 complete → streak 1
  - Day 2 complete → streak 2
  - Skip day 3, complete day 4 → streak 1, bestStreak 2
  - Same day replay → no streak change
- Date edge case: completing at 23:59 UTC vs 00:01 UTC

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| PRNG algorithm produces biased puzzles | Medium | Use well-known xorshift64; validate puzzle quality in tests |
| Timezone confusion | Medium | Strictly use UTC everywhere, document clearly |
| User changes device date to cheat streak | Low | Acceptable for local-only MVP; server validation in Phase 3 |

## Security Considerations
- Notification permission: request only when user enables reminder
- No network calls, no user data transmitted

## Next Steps
- Phase 3 (server-seeded daily) could replace local seeding for anti-cheat
- Daily challenge stats feed into Game Center leaderboard (Phase 4)
