# Phase 2: Statistics Screen

## Context Links
- [SudokuGameState.swift](../../SmartGames/Games/Sudoku/Models/SudokuGameState.swift) -- existing `SudokuStats` struct
- [SudokuGameViewModel.swift](../../SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift) -- `saveStats()` method
- [PersistenceService.swift](../../SmartGames/SharedServices/Persistence/PersistenceService.swift) -- keys pattern
- [SudokuLobbyView.swift](../../SmartGames/Games/Sudoku/Views/SudokuLobbyView.swift) -- entry point for stats nav
- [AppRoutes.swift](../../SmartGames/Navigation/AppRoutes.swift)

## Overview
- **Priority:** P1 -- pure local feature, no external dependencies
- **Status:** ✅ Complete
- **Effort:** 4h
- **Description:** Dedicated statistics screen showing games played, win %, average time, best time, current streak, and best streak per difficulty. Accessible from lobby toolbar.

## Key Insights
- `SudokuStats` already exists with `gamesPlayed`, `gamesWon`, `bestTimeSeconds`, `totalMistakes`
- Stats saved per difficulty via `PersistenceService.Keys.sudokuStats(difficulty:)`
- `saveStats()` in `SudokuGameViewModel` only increments on win -- need to also track losses
- Missing fields: `totalTimeSeconds` (for average), `currentStreak`, `bestStreak`
- Stats are lightweight Codable structs -- extending is backward-compatible if defaults provided

## Requirements

### Functional
- FR1: Stats screen shows per-difficulty tab/segment: Easy, Medium, Hard, Expert, and "All"
- FR2: Metrics displayed: Games Played, Games Won, Win %, Average Time, Best Time, Current Streak, Best Streak
- FR3: Stats screen accessible from lobby toolbar (chart icon)
- FR4: "All" tab aggregates across difficulties
- FR5: Stats reset option (with confirmation alert)

### Non-Functional
- NFR1: Stats load instantly (local UserDefaults)
- NFR2: Backward compatible -- existing stats data must not be lost on upgrade

## Architecture

### Extended SudokuStats
```swift
struct SudokuStats: Codable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var bestTimeSeconds: Int = Int.max
    var totalMistakes: Int = 0
    // New fields
    var totalTimeSeconds: Int = 0      // sum of all completed game times
    var currentStreak: Int = 0         // consecutive wins
    var bestStreak: Int = 0            // highest consecutive wins ever
}
```

New fields default to 0, so decoding existing data just fills defaults -- backward compatible.

### StatisticsService
```swift
@MainActor
final class StatisticsService: ObservableObject {
    func stats(for difficulty: SudokuDifficulty) -> SudokuStats
    func aggregateStats() -> SudokuStats           // "All" tab
    func recordWin(difficulty:, elapsedSeconds:, mistakes:)
    func recordLoss(difficulty:)
    func resetStats(for difficulty: SudokuDifficulty?)  // nil = all
}
```

### Computed Display Values
```
Win %         = gamesWon / gamesPlayed * 100
Average Time  = totalTimeSeconds / gamesWon  (only won games counted)
Best Time     = bestTimeSeconds (Int.max → "--:--")
```

## Files to Create

| File | Purpose |
|------|---------|
| `SharedServices/Statistics/StatisticsService.swift` | Stats read/write logic |
| `Games/Sudoku/Views/SudokuStatisticsView.swift` | Stats screen UI |

## Files to Modify

| File | Change |
|------|--------|
| `Games/Sudoku/Models/SudokuGameState.swift` | Add `totalTimeSeconds`, `currentStreak`, `bestStreak` to `SudokuStats` |
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Replace inline `saveStats()` with `StatisticsService.recordWin/recordLoss` calls |
| `AppEnvironment.swift` | Add `StatisticsService` |
| `SmartGamesApp.swift` | Inject `StatisticsService` as environment object |
| `Navigation/AppRoutes.swift` | Add `.sudokuStatistics` route |
| `ContentView.swift` | Register `.sudokuStatistics` navigation destination |
| `Games/Sudoku/Views/SudokuLobbyView.swift` | Add stats toolbar button (chart.bar icon) navigating to stats |

## Implementation Steps

1. **Extend `SudokuStats`**
   - Add `totalTimeSeconds: Int = 0`, `currentStreak: Int = 0`, `bestStreak: Int = 0`
   - Existing persisted data decodes fine (Codable defaults)

2. **Create `StatisticsService.swift`**
   - Init with `PersistenceService`
   - `func stats(for:) -> SudokuStats` -- loads from persistence
   - `func aggregateStats() -> SudokuStats` -- sums across all difficulties
   - `func recordWin(difficulty:, elapsedSeconds:, mistakes:)`:
     - Load stats, increment `gamesPlayed`, `gamesWon`
     - Add `elapsedSeconds` to `totalTimeSeconds`
     - Update `bestTimeSeconds` if lower
     - Add mistakes to `totalMistakes`
     - Increment `currentStreak`, update `bestStreak` if new record
     - Save
   - `func recordLoss(difficulty:)`:
     - Increment `gamesPlayed`, reset `currentStreak = 0`, save
   - `func resetStats(for:)` -- delete key(s), confirm via alert in UI

3. **Update `SudokuGameViewModel.saveStats()`**
   - Replace inline stats saving with `statisticsService.recordWin(...)`
   - Add `recordLoss` call in the game-over (lost) path
   - Add `StatisticsService` as init dependency

4. **Wire into `AppEnvironment`**
   - `let statistics: StatisticsService`
   - Init: `self.statistics = StatisticsService(persistence: persistence)`

5. **Add route**
   - `AppRoute`: add `case sudokuStatistics`
   - `ContentView`: add `.navigationDestination(for:)` case

6. **Create `SudokuStatisticsView.swift`**
   - Segmented picker: Easy | Medium | Hard | Expert | All
   - Grid/list of stat cards:
     - Games Played (number)
     - Win Rate (% with circular progress indicator)
     - Best Time (mm:ss)
     - Average Time (mm:ss)
     - Current Streak (flame icon + number)
     - Best Streak (trophy icon + number)
   - "Reset Statistics" button at bottom with confirmation `.alert`

7. **Update `SudokuLobbyView`**
   - Replace placeholder trophy icon with chart.bar icon
   - Wire to `router.navigate(to: .sudokuStatistics)`

## Todo List

- [ ] Extend `SudokuStats` with new fields (backward-compatible defaults)
- [ ] Create `StatisticsService` with read/write/aggregate/reset methods
- [ ] Wire `StatisticsService` into `AppEnvironment` and `SmartGamesApp`
- [ ] Update `SudokuGameViewModel` to use `StatisticsService.recordWin/recordLoss`
- [ ] Add `.sudokuStatistics` route to `AppRoute` and `ContentView`
- [ ] Create `SudokuStatisticsView` with difficulty segmented picker
- [ ] Add stats navigation from `SudokuLobbyView` toolbar
- [ ] Handle empty state (no games played yet)
- [ ] Add reset confirmation alert
- [ ] Verify backward compatibility with existing persisted stats

## Acceptance Criteria

- [ ] Stats screen shows correct data for each difficulty
- [ ] "All" aggregation works correctly
- [ ] Win/loss properly update stats including streaks
- [ ] Best time only updates when new time is lower
- [ ] Average time calculated only from won games
- [ ] Reset clears all stats with confirmation
- [ ] Existing v1 stats data preserved on upgrade
- [ ] Empty state shows "No games played" gracefully

## Tests Needed

- `StatisticsService.recordWin`: verify all fields update correctly
- `StatisticsService.recordLoss`: verify streak resets, gamesPlayed increments
- `StatisticsService.aggregateStats`: verify cross-difficulty aggregation
- `SudokuStats` backward compat: decode JSON missing new fields, verify defaults
- Streak logic: win-win-lose-win should produce currentStreak=1, bestStreak=2

## Security Considerations
- None -- local data only, no PII

## Next Steps
- Phase 3 (Daily Challenge) will integrate with StatisticsService for daily streak
- Phase 4 (Game Center) reads bestTimeSeconds for leaderboard submission
