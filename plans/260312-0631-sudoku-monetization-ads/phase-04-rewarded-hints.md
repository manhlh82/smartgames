# Phase 04 — Rewarded Hints (Revised)

**Priority:** P1 | **Effort:** 3h | **PR:** PR-14 | **Depends on:** PR-11

---

## Context Links
- [SudokuGameViewModel.swift](../../SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift) -- hint system (L217-257, L409-440)
- [PersistenceService keys](../../SmartGames/SharedServices/Persistence/PersistenceService.swift) -- `sudokuHintsRemaining`
- [MonetizationConfig](phase-01-monetization-config-model.md) -- `rewardedHintAmount`, `levelCompleteHintReward`, `maxHintCap`

---

## Overview

Revise the hint system to enforce a max cap, add level-completion hint rewards, and ensure all grant paths respect the cap. Currently hints are unbounded -- `grantHintsAfterAd()` adds +3, `grantHintsFromPurchase()` adds +10, no ceiling.

---

## Current State vs Target

| Aspect | Current | Target |
|--------|---------|--------|
| Ad reward | +3 hints, no cap | +3 hints, capped at `maxHintCap` (3) |
| Level complete reward | None | +1 hint, capped at `maxHintCap` (3) |
| IAP hint pack | +10 hints, no cap | +12 hints ($0.99), **no cap** (IAP exempts cap -- user paid) |
| Max balance | Unbounded | 3 (for free/ad hints); unlimited for IAP |
| Initial hints | `difficulty.freeHints` | `difficulty.freeHints` (unchanged, typically 3) |
| Persistence | `sudokuHintsRemaining` in UserDefaults | Same key, same mechanism |
| Restored on launch | Yes (from persistence) | Yes (unchanged) |
| Displayed in UI | Toolbar hint button badge | Same (unchanged) |

---

## Cap Enforcement Strategy

Single helper method in ViewModel, called by all non-IAP grant paths:

```swift
// SudokuGameViewModel

/// Grants hints up to the configured cap. Returns actual amount granted.
/// IAP grants bypass the cap (user paid real money).
@discardableResult
private func grantHints(_ amount: Int, bypassCap: Bool = false) -> Int {
    let config = monetizationConfig
    let effectiveAmount: Int
    if bypassCap {
        effectiveAmount = amount
    } else {
        effectiveAmount = min(amount, config.maxHintCap - hintsRemaining)
    }
    guard effectiveAmount > 0 else {
        // Cap reached — log analytics
        analytics.log(.hintCapReached(
            currentHints: hintsRemaining,
            maxCap: config.maxHintCap
        ))
        return 0
    }
    hintsRemaining += effectiveAmount
    persistence.save(hintsRemaining, key: PersistenceService.Keys.sudokuHintsRemaining)
    return effectiveAmount
}
```

---

## Grant Paths (Updated)

### 1. Rewarded Ad (+3, capped)

```swift
func grantHintsAfterAd() {
    let granted = grantHints(monetizationConfig.rewardedHintAmount)
    gamePhase = .playing
    if granted > 0 {
        applyHint() // auto-use one hint immediately
    }
}
```

### 2. Level Completion (+1, capped)

Add to `checkWin()` after recording stats:

```swift
// In checkWin(), after statisticsService.recordWin(...)
grantHints(monetizationConfig.levelCompleteHintReward)
analytics.log(.hintEarnedFromLevel(
    difficulty: puzzle.difficulty.rawValue,
    hintsAfter: hintsRemaining
))
```

### 3. IAP Hint Pack (+12, bypasses cap)

```swift
func grantHintsFromPurchase() {
    grantHints(12, bypassCap: true)
    if gamePhase == .needsHintAd {
        gamePhase = .playing
        applyHint()
    }
}
```

---

## Hint Display in UI

Already implemented: hint count shown as badge on hint toolbar button. Verify it updates reactively for all grant paths.

When hints at cap after level complete, show brief toast: "Hints full! (3/3)" -- optional, low priority.

---

## Persistence Details

| Key | Type | When Written | When Read |
|-----|------|-------------|-----------|
| `sudoku.hints.remaining` | `Int` | After every grant/use | On ViewModel init, on app launch |

- On fresh install: defaults to `difficulty.freeHints` (3 for Easy/Medium, 2 for Hard, 1 for Expert -- per existing code)
- Persists across sessions, levels, and app restarts
- Shared across all Sudoku games (not per-puzzle)

---

## Edge Cases

1. **Hint count already at cap, user watches ad:** Ad still plays (cannot prevent SDK callback), but `grantHints` returns 0. Log `hint_cap_reached`. Consider: disable "Watch Ad for Hints" button when at cap.
2. **User at 2 hints, ad grants 3:** Clamped to 1 granted (2 + 1 = 3 cap).
3. **IAP purchased while at cap:** Hints go above cap (12 added to 3 = 15). This is intentional -- user paid, should feel generous.
4. **Hints above cap from IAP, then level complete:** No additional grant (already above cap). `grantHints` checks `maxHintCap - hintsRemaining` which is negative, so 0 granted.

---

## Files to Modify

| File | Change |
|------|--------|
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Add `grantHints(_:bypassCap:)`; refactor `grantHintsAfterAd()`, `grantHintsFromPurchase()`; add level-complete grant in `checkWin()` |
| `Games/Sudoku/Views/SudokuGameView.swift` | Disable "Watch Ad" hint button when `hintsRemaining >= maxHintCap` (UX improvement) |

---

## Acceptance Criteria

- [ ] `hintsRemaining` never exceeds `maxHintCap` (3) from ad/level grants
- [ ] IAP hint pack grants +10 regardless of cap
- [ ] Level completion grants +1 hint (capped)
- [ ] Hint count persists across app restart
- [ ] Hint count displayed in toolbar badge updates immediately on all grant paths
- [ ] "Watch Ad" hint option disabled/hidden when at cap (prevents wasted ad view)
- [ ] Analytics fires for each grant source

## Tests

- Unit: `grantHints(3)` when `hintsRemaining=0` -> `hintsRemaining=3`
- Unit: `grantHints(3)` when `hintsRemaining=2` -> `hintsRemaining=3` (clamped)
- Unit: `grantHints(3)` when `hintsRemaining=3` -> `hintsRemaining=3` (no change, cap reached logged)
- Unit: `grantHints(12, bypassCap: true)` when `hintsRemaining=3` -> `hintsRemaining=15`
- Unit: level complete calls `grantHints(1)` and persists
- Unit: persistence round-trip (save, reload ViewModel, hints restored)
