# Phase 10 — Sudoku Completion Feedback (3×3 Subgrid + Full Puzzle)

**PR:** PR-12
**Priority:** High
**Status:** Completed
**Depends on:** Phase 09 (SFX hooks in SoundService)

## Overview

Two distinct feedback moments:

1. **3×3 Subgrid Completion** — when all 9 cells in a box are correctly filled, briefly animate that box with a short celebration effect and play a chime.
2. **Full Puzzle Completion** — when the entire board is solved, show a victory overlay, play a completion sound, grant +1 hint (capped), persist stats, and fire analytics.

---

## 1. 3×3 Subgrid Completion

### Trigger Condition

Fires after every valid cell entry (number placement, not pencil mark) when:
- All 9 cells in the subgrid have non-zero values
- All 9 values are correct (cross-check against solution)
- This subgrid has not already fired its celebration this game session

Evaluated in `SudokuGameViewModel.checkSubgridCompletion(at:)` called after each `placeNumber`.

### One-Time Guard

```swift
// In SudokuGameViewModel
private var celebratedSubgrids: Set<Int> = []   // subgrid index 0–8, cleared on new game

func checkSubgridCompletion(at position: CellPosition) {
    let subgridIndex = (position.row / 3) * 3 + (position.col / 3)
    guard !celebratedSubgrids.contains(subgridIndex) else { return }
    guard isSubgridComplete(subgridIndex) else { return }
    celebratedSubgrids.insert(subgridIndex)
    triggerSubgridCelebration(subgridIndex)
}
```

`celebratedSubgrids` is **session-only** (not persisted). Resetting a game clears it.

### Visual Style

- **Duration:** ≤ 0.8s total
- **Effect:** Brief "flash + scale pulse" on the 3×3 box overlay
  - Scale: 1.0 → 1.04 → 1.0 (spring, damping 0.6)
  - Background tint: soft gold/amber fade in then out
  - No confetti, no modal — non-blocking, happens behind cells
- **Implementation:** `SudokuBoardView` observes `celebratingSubgrid: Int?` from ViewModel. When set, applies `.scaleEffect` + `.colorMultiply` to the matching box overlay. Auto-clears after animation.

### ViewModel State

```swift
@Published var celebratingSubgrid: Int? = nil  // 0–8, nil = none active
```

After animation completes (~0.8s), view sets this back to nil via `.onAnimationCompleted` or `DispatchQueue.main.asyncAfter`.

### Sound

`soundService.play(audioConfig.subgridCompleteSFX)` — short positive chime (~0.3s).

### Board State / Re-render Safety

- Celebration fires once on the frame where the cell is placed
- Board re-renders from state changes will NOT re-trigger animation (guarded by `celebratedSubgrids`)
- `celebratingSubgrid` is set async to avoid animation conflicts with cell placement highlight

### Analytics

```swift
static func subgridCompleted(subgridIndex: Int, difficulty: String) -> AnalyticsEvent
```

---

## 2. Full Puzzle Completion

### Existing State

`SudokuGameViewModel` already transitions to `gamePhase = .won` in `checkWin()` and calls `grantHints(levelCompleteHintReward)`. A win overlay exists.

### Gaps to Fill

| Gap | Fix |
|-----|-----|
| +1 hint grant not confirmed audibly/visually | Show hint reward in victory UI |
| No completion sound | Call `soundService.play(audioConfig.puzzleCompleteSFX)` in `checkWin()` |
| Victory overlay UX underspecified | Define below |
| Analytics: reward granted vs. blocked | Add both events |

### Completion Flow (revised `checkWin()`)

```
1. Validate board is fully solved
2. Stop timer
3. Play puzzleCompleteSFX
4. Grant +1 hint via grantHints(levelCompleteHintReward) → returns actual granted (0 or 1)
5. Persist updated hintsRemaining
6. Fire analytics: puzzleCompleted + hintRewardGranted or hintRewardBlocked
7. Set gamePhase = .won
8. Schedule interstitial ad (existing logic, unchanged)
```

Step 4 already handles the cap — `grantHints` returns 0 if at cap. No additional logic needed.

### Victory UI Overlay

**File:** `SudokuWinOverlay.swift` (new, or extend existing win view)

Layout:
```
┌─────────────────────────────┐
│   🎉  Puzzle Complete!       │
│                             │
│   Time: 4:32                │
│   Mistakes: 1               │
│                             │
│   +1 Hint earned!           │  ← show only if granted > 0
│   (or: Hint inventory full) │  ← show only if granted == 0
│                             │
│   [ Next Puzzle ]           │
│   [ Back to Menu ]          │
└─────────────────────────────┘
```

- No confetti library (avoid SPM dependency for v1)
- Simple: star burst SVG/SF Symbol scale-in animation, title fade-in, stats slide-up
- Haptic: `.notificationFeedback(.success)` on appear
- Music: fades out when overlay appears, stays quiet until user navigates away

### +1 Hint Display Logic

```swift
// In checkWin():
let granted = grantHints(monetizationConfig.levelCompleteHintReward)
// Pass `granted` into win overlay so UI can show correct message
```

`SudokuGameViewModel.hintsGrantedOnWin: Int` (published, cleared on new game).

### Persistence

| Key | Action |
|-----|--------|
| `sudoku.hints.remaining` | Updated by `grantHints` (already) |
| `sudoku.stats.{difficulty}` | Update completed count, best time (existing StatisticsService) |
| `sudoku.activeGame` | Clear saved game state after win (already) |

No new persistence keys needed.

### Analytics Events (new)

```swift
static func puzzleCompleted(difficulty: String, timeSeconds: Int, mistakeCount: Int, hintsUsed: Int) -> AnalyticsEvent
static func completionHintGranted(hintsAfter: Int) -> AnalyticsEvent
static func completionHintBlocked(reason: String) -> AnalyticsEvent   // reason = "cap_reached"
```

---

## Related Files

### Modify
- `SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift` — `checkWin()`, `checkSubgridCompletion()`, published state
- `SmartGames/Games/Sudoku/Views/SudokuBoardView.swift` — subgrid celebration overlay
- `SmartGames/SharedServices/Analytics/AnalyticsEvent+Sudoku.swift` — new events

### Create
- `SmartGames/Games/Sudoku/Views/SudokuWinOverlay.swift` — revised victory UI
- `SmartGames/Games/Sudoku/Views/SudokuSubgridCelebrationOverlay.swift` — animation layer

---

## Acceptance Criteria

**3×3 Subgrid:**
- [ ] Animation fires exactly once per subgrid per game session
- [ ] Animation does not fire for incorrect fills (validation check required)
- [ ] Animation completes in ≤ 0.8s and does not block input
- [ ] Chime plays (if SFX enabled)
- [ ] Resuming a saved game does not re-celebrate already-completed subgrids (session-only guard is acceptable since saves restore board state — already-filled cells won't trigger cell-placement again)
- [ ] Analytics event fires once per subgrid completion

**Full Puzzle:**
- [ ] Completion sound plays on win
- [ ] Victory overlay shows time, mistakes, hints used
- [ ] If `granted > 0`: "+1 Hint earned!" displayed
- [ ] If `granted == 0` (cap reached): "Hint inventory full" displayed
- [ ] Haptic success feedback on win
- [ ] Analytics fires: puzzleCompleted + correct reward event

## Tests

- `SudokuGameViewModelTests`: subgrid completion trigger, one-time guard, `checkWin` grant path
- `SudokuGameViewModelTests`: hint grant vs. blocked at cap (both analytics branches)
- Manual: complete a subgrid mid-game — animation fires; complete puzzle — overlay appears with correct hint message
