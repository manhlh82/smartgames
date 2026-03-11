---
phase: 3
title: "New Features"
status: pending
effort: 2h
---

# Phase 3: New Features (High-Impact, Low-Effort)

## Context
Features that would make the Sudoku game feel complete and polished. Prioritized by impact-to-effort ratio. Only recommending features that are achievable in ~2h total.

## Recommended Features

### 1. Auto-Remove Error After Delay (HIGH impact, LOW effort)
**Current:** Error cells stay red permanently until user erases them manually.
**Problem:** User must tap cell, then erase, then re-enter. Friction.
**Improvement:** Auto-clear incorrect value after 1.5s delay. Cell flashes red, then reverts to empty. Mistake still counts.

**Files to modify:**
- `SudokuGameViewModel.swift` `placeNumber()` -- after error detected, schedule delayed clear

**Implementation:**
```swift
// In placeNumber, after !isCorrect branch:
Task { @MainActor in
    try? await Task.sleep(nanoseconds: 1_500_000_000)
    guard puzzle.board[pos.row][pos.col].hasError else { return }
    puzzle.board[pos.row][pos.col].value = nil
    puzzle.board[pos.row][pos.col].hasError = false
    scheduleAutoSave()
}
```

### 2. Smart Pencil Auto-Fill (MEDIUM impact, LOW effort)
**Current:** User manually enters pencil marks one by one.
**Improvement:** Long-press pencil button to auto-fill all valid candidates for empty cells in the current row/col/box of selected cell (or all empty cells).

**Files to modify:**
- `SudokuGameViewModel.swift` -- add `autoFillPencilMarks()` method
- `SudokuToolbarView.swift` -- add `.onLongPressGesture` to pencil button

**Implementation:**
```swift
func autoFillPencilMarks() {
    for row in 0..<9 {
        for col in 0..<9 where puzzle.board[row][col].isEmpty {
            let used = SudokuBoardUtils.usedValues(in: puzzle.board, row: row, col: col)
            puzzle.board[row][col].pencilMarks = Set(1...9).subtracting(used)
        }
    }
    haptics.impact(.medium)
    scheduleAutoSave()
}
```

### 3. Remaining Count Per Number (MEDIUM impact, TRIVIAL effort)
**Current:** Number pad shows 1-9 with dimming for completed numbers.
**Improvement:** Show small count badge (e.g., "x3") on each number indicating how many more of that digit need to be placed.

**Files to modify:**
- `SudokuNumberPadView.swift` -- accept `remainingCounts: [Int: Int]`
- `SudokuGameViewModel.swift` -- add computed `remainingCounts`

### 4. Quick Note Toggle Per Cell (LOW impact, LOW effort)
**Current:** Must toggle pencil mode globally, tap number, toggle back.
**Improvement:** Double-tap a number on the pad to place it as pencil mark (without toggling pencil mode).

**Files to modify:**
- `SudokuNumberPadView.swift` -- add double-tap gesture
- `SudokuGameViewModel.swift` -- add `placePencilMark(_ n: Int)` method

---

## Features NOT Recommended (YAGNI)

| Feature | Why Not |
|---------|---------|
| Difficulty progression system | Over-engineering; users already pick difficulty |
| Auto-advance to next puzzle | "Next Puzzle" button on win screen is sufficient |
| Undo for pencil marks | Too niche; pencil edits are trivial to redo |
| Animated board transitions | High effort, low ROI for puzzle game |
| Multiplayer/race mode | Completely different product scope |
| Timer-based scoring | Star rating already covers this |

---

## Implementation Steps

### Step 1: Auto-remove error
1. In `placeNumber()`, after setting `hasError = true`, schedule async clear
2. Guard that cell still has error before clearing (user might erase first)
3. No snapshot needed -- error clear is visual convenience, not undoable action

### Step 2: Smart pencil auto-fill
1. Add `autoFillPencilMarks()` to ViewModel
2. Add `usedValues(in:row:col:)` to `SudokuBoardUtils` if not already present
3. Add long-press gesture to pencil button in toolbar
4. Push snapshot before auto-fill (it's undoable)

### Step 3: Remaining count per number
1. Add computed property `remainingCounts: [Int: Int]` to ViewModel
2. For each digit 1-9: `9 - count(of digit on board)`
3. Pass to `SudokuNumberPadView`
4. Show small text below/beside each number

### Step 4: Double-tap pencil (if time permits)
1. Add `onDoubleTap` callback to number pad
2. Route to `placePencilMark()` which always writes pencil mark regardless of mode

---

## Todo List
- [ ] Implement auto-remove error after delay
- [ ] Implement smart pencil auto-fill (long-press)
- [ ] Add remaining count badges to number pad
- [ ] (Optional) Double-tap pencil shortcut

## Priority Order
1. Auto-remove error (biggest UX friction reduction)
2. Remaining count per number (most-requested in Sudoku apps)
3. Smart pencil auto-fill (power user feature)
4. Double-tap pencil (nice-to-have)

## Success Criteria
- Auto-remove error works without disrupting undo stack
- Pencil auto-fill is undoable
- Remaining counts update reactively on number placement
- All features compile and don't break existing functionality

## Risk Assessment
- **Auto-remove error timing:** If user rapidly places numbers, multiple timers could fire. Mitigate by checking cell state before clearing.
- **Auto-fill pencil:** Could overwhelm board visually. Consider limiting to selected cell's peers only as alternative.
