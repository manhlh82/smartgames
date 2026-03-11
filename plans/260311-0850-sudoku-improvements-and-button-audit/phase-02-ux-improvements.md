---
phase: 2
title: "UX Improvements"
status: pending
effort: 3h
---

# Phase 2: UX Improvements

## Context
Polish pass to bring the Sudoku experience to production quality. Focus on high-impact, low-effort wins.

## Identified UX Gaps

### 1. No Visual Feedback When a Number Is Fully Placed (HIGH impact, LOW effort)
**Current:** Number pad dims completed digits but nothing happens on the board.
**Improvement:** Brief highlight animation on all 9 cells of that digit when the last instance is placed. Gives satisfying closure feedback.

**Files to modify:**
- `SudokuGameViewModel.swift` -- add `@Published var lastCompletedNumber: Int?` that auto-resets
- `SudokuCellView.swift` -- add pulse animation when cell value matches `lastCompletedNumber`

**Implementation:**
```swift
// ViewModel: after placeNumber succeeds
if completedNumbers.contains(n) && !previousCompleted.contains(n) {
    lastCompletedNumber = n
    Task {
        try? await Task.sleep(nanoseconds: 800_000_000)
        lastCompletedNumber = nil
    }
}
```

### 2. No Cell Selection Indicator on Number Pad (MEDIUM impact, LOW effort)
**Current:** When a cell with value X is selected, no indication on number pad showing which number it is.
**Improvement:** Highlight the corresponding number button on the pad when a filled cell is selected.

**Files to modify:**
- `SudokuNumberPadView.swift` -- accept optional `selectedNumber: Int?` param
- `SudokuGameView.swift` -- pass selected cell's value to number pad

### 3. Toolbar Buttons Disabled During Non-Playing Phases (MEDIUM impact, LOW effort)
**Current:** Undo/Erase/Pencil/Hint are all active even when game is won or lost (overlays cover them but taps can still register on edges).
**Improvement:** Disable all toolbar actions when `gamePhase != .playing`.

**Files to modify:**
- `SudokuToolbarView.swift` -- wrap in `.disabled(viewModel.gamePhase != .playing)`

### 4. No Confirmation Before Restarting (LOW impact, LOW effort)
**Current:** "Restart" from pause overlay immediately resets all progress.
**Improvement:** Show confirmation alert before restart to prevent accidental loss.

**Files to modify:**
- `SudokuPauseOverlayView.swift` -- add `@State var showRestartConfirm`
- Or handle in `SudokuGameView.swift` with `.alert`

### 5. Timer Hidden When Paused -- No Indicator (LOW impact, TRIVIAL effort)
**Current:** Timer disappears during pause. User returns and doesn't know their time.
**Improvement:** Show frozen time with "PAUSED" label or keep time visible but grayed out.

**Files to modify:**
- `SudokuGameView.swift` statsBar -- always show time, add `.opacity(0.4)` when paused

### 6. Win Screen Could Be Richer (MEDIUM impact, MEDIUM effort)
**Current:** Static card with stars, time, mistakes, buttons.
**Improvement:** Add simple star entrance animation (scale from 0 with delay per star). Low effort, high delight.

**Files to modify:**
- `SudokuWinView.swift` -- add `@State var animateStars` with `.onAppear` trigger

### 7. Hints Remaining Badge on Toolbar (LOW impact, TRIVIAL effort)
**Current:** Hint count only visible in accessibility label + ad icon when 0.
**Improvement:** Show small badge with remaining hint count below "Hint" label.

**Files to modify:**
- `SudokuToolbarView.swift` hintButton -- add count text

---

## Implementation Steps

### Step 1: Number completion animation
1. Add `@Published var lastCompletedNumber: Int?` to ViewModel
2. Track previous completed set before `placeNumber` logic
3. Set + auto-reset after 800ms
4. In `SudokuCellView`, add `.scaleEffect` animation when value matches

### Step 2: Number pad selection highlight
1. Add `selectedNumber: Int?` param to `SudokuNumberPadView`
2. Compute from `viewModel.selectedCell` value in `SudokuGameView`
3. Apply accent border/ring to matching button

### Step 3: Toolbar disable during non-playing
1. Add `.disabled(viewModel.gamePhase != .playing)` to entire `SudokuToolbarView` HStack

### Step 4: Restart confirmation
1. Add `@State private var showRestartConfirm = false` in `SudokuGameView`
2. Change pause overlay's `onRestart` to set flag
3. Add `.alert("Restart?")` confirmation

### Step 5: Show paused timer
1. Remove `if viewModel.gamePhase != .paused` condition from timer text
2. Add `.opacity(viewModel.gamePhase == .paused ? 0.4 : 1)`

### Step 6: Star entrance animation
1. Add `@State var showStars = false` to `SudokuWinView`
2. Apply `.scaleEffect(showStars ? 1 : 0)` with staggered `.delay(Double(i) * 0.15)`
3. Set `showStars = true` in `.onAppear`

### Step 7: Hint count badge
1. Replace "Hint" label with "Hint (\(count))" or small badge overlay

---

## Todo List
- [ ] Add number completion celebration animation
- [ ] Add number pad selection highlight
- [ ] Disable toolbar during non-playing phases
- [ ] Add restart confirmation dialog
- [ ] Show paused timer (grayed out)
- [ ] Add star entrance animation on win screen
- [ ] Add hint count badge

## Priority Order
1. Toolbar disable during non-playing (prevents edge-case bugs)
2. Number completion animation (most satisfying feedback)
3. Show paused timer
4. Star entrance animation
5. Number pad selection highlight
6. Hint count badge
7. Restart confirmation

## Success Criteria
- All 7 UX improvements implemented and compiling
- Animations are subtle (< 1s duration), not distracting
- No performance regressions on older devices
