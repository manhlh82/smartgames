---
phase: 1
title: "Button Audit & Fixes"
status: completed
effort: 3h
---

# Phase 1: Button Audit & Fixes

## Context
- [SudokuGameViewModel.swift](../../SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift)
- [SudokuGameView.swift](../../SmartGames/Games/Sudoku/Views/SudokuGameView.swift)
- [SudokuToolbarView.swift](../../SmartGames/Games/Sudoku/Views/SudokuToolbarView.swift)
- [SudokuNumberPadView.swift](../../SmartGames/Games/Sudoku/Views/SudokuNumberPadView.swift)

## Audit Results per Button

### 1. Number Pad (1-9) -- OK
- Placement works: checks `isGiven`, pushes snapshot, validates against solution
- Pencil mode toggles marks correctly
- Completed numbers (9 instances) dimmed + disabled
- **No issues found**

### 2. Undo Button -- OK (minor gap)
- Restores board + mistake count from snapshot stack
- Disabled state shown when stack empty
- **Gap:** Pencil mark changes are NOT undoable (no snapshot pushed). Consider if this is desired behavior or a bug. Recommend: leave as-is (YAGNI -- pencil marks are lightweight edits).

### 3. Erase Button -- NEEDS FIX
- Logic works: clears value, pencil marks, error flag; guards against given cells
- **Bug:** No visual disabled state. Button always looks active even when:
  - No cell selected
  - Selected cell is a given
  - Selected cell is already empty
- **Fix:** Add `isDisabled` parameter based on selection state

### 4. Pencil Mode Toggle -- OK
- Toggles `isPencilMode`, shows active state (accent color)
- **No issues found**

### 5. Hint Button -- OK
- Decrements hints, reveals cell via validator, auto-clears peer pencil marks
- 0-hints triggers `.needsHintAd` -> alert -> rewarded ad flow
- IAP hint pack grants 10 hints via polling observer
- **No issues found**

### 6. Pause Button (toolbar trailing) -- OK
- Guards `gamePhase == .playing`, stops timer, triggers auto-save
- Icon swaps between pause/play
- **No issues found**

### 7. Resume Button (pause overlay + toolbar) -- OK
- Guards `gamePhase == .paused`, restarts timer
- **No issues found**

### 8. Back Button -- NEEDS FIX
- **Bug:** Calls `router.pop()` without saving game state first
- Game will be lost if user navigates back mid-game (auto-save is debounced 500ms, may not have fired)
- **Fix:** Call `viewModel.autoSave()` before `router.pop()`

### 9. Win Flow -- MINOR ISSUE
- Correctly transitions to `.won`, stops timer, records stats, submits Game Center
- Clears active game from persistence
- "Next Puzzle" calls `router.pop()` (returns to lobby)
- **Gap:** "Next Puzzle" doesn't actually start next puzzle -- it just goes to lobby. Label is slightly misleading but acceptable.

### 10. Lose Flow -- BUG
- Correctly transitions to `.lost`, stops timer, records loss
- "Try Again" calls `viewModel.restart()` -- works correctly
- **Bug:** "Watch Ad to Continue" sets `mistakeCount = mistakeLimit - 1` and `gamePhase = .playing`, then calls `viewModel.resume()`. But `resume()` guards `gamePhase == .paused` and returns early. Timer never restarts.
- **Fix:** Replace `viewModel.resume()` with `viewModel.startTimer()` (or add a dedicated `continueAfterAd()` method)

### 11. Restart (from pause) -- MINOR ISSUE
- Calls `viewModel.restart()` which sets `.playing` and calls `startTimer()`
- `startTimer()` cancels previous timer first -- OK, no double-timer bug
- **No fix needed** (I was wrong in initial assessment; `startTimer()` does cancel first)

### 12. Star Rating Logic -- BUG
- Line 302: `if mistakeCount <= 1 || elapsedSeconds < 600 { return 2 }`
- Should be `&&` not `||` -- currently a game with 3 mistakes in 5 minutes gets 2 stars
- **Fix:** Change `||` to `&&`

---

## Implementation Steps

### Fix 1: Back button auto-save
**File:** `SudokuGameView.swift` line ~106
```swift
// Before
Button { router.pop() } label: { ... }
// After
Button {
    viewModel.autoSave()
    router.pop()
} label: { ... }
```

### Fix 2: Erase button disabled state
**File:** `SudokuToolbarView.swift` line ~13
Add computed property to ViewModel:
```swift
var isEraseAvailable: Bool {
    guard let pos = selectedCell else { return false }
    let cell = puzzle.board[pos.row][pos.col]
    return !cell.isGiven && (cell.value != nil || !cell.pencilMarks.isEmpty)
}
```
Then pass `isDisabled: !viewModel.isEraseAvailable` to `toolButton()`.

### Fix 3: Lost screen ad-continue timer
**File:** `SudokuGameView.swift` line ~178
```swift
// Before
viewModel.mistakeCount = viewModel.mistakeLimit - 1
viewModel.gamePhase = .playing
viewModel.resume()
// After -- use a dedicated method
viewModel.continueAfterAd()
```
**File:** `SudokuGameViewModel.swift` -- add method:
```swift
func continueAfterAd() {
    mistakeCount = mistakeLimit - 1
    gamePhase = .playing
    startTimer()
    analytics.log(.sudokuGameContinuedAfterAd(difficulty: puzzle.difficulty.rawValue))
    scheduleAutoSave()
}
```

### Fix 4: Star rating logic
**File:** `SudokuGameViewModel.swift` line ~302
```swift
// Before
if mistakeCount <= 1 || elapsedSeconds < 600 { return 2 }
// After
if mistakeCount <= 1 && elapsedSeconds < 600 { return 2 }
```

---

## Todo List
- [x] Fix back button to call `autoSave()` before `pop()`
- [x] Add `isEraseAvailable` computed property + disable erase button
- [x] Add `continueAfterAd()` method to ViewModel
- [x] Update lost overlay to use `continueAfterAd()`
- [x] Fix star rating `||` to `&&`
- [x] Verify all fixes compile

## Success Criteria
- All 5 fixes implemented and compiling
- Back button preserves game state
- Erase button visually disabled when not applicable
- Ad-continue on lost screen properly restarts timer
- Star rating awards 2 stars only when BOTH conditions met
