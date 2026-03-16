# Phase 05 — Rewarded Mistake Reset

**Priority:** P1 | **Effort:** 3h | **PR:** PR-15 | **Depends on:** PR-11

---

## Context Links
- [SudokuGameViewModel.swift](../../SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift) -- `mistakeCount`, `mistakeLimit`, `continueAfterAd()`
- [MonetizationConfig](phase-01-monetization-config-model.md) -- `mistakeResetEnabled`, `mistakeResetUsesPerLevel`

---

## Overview

New feature: during gameplay, when a player has 1+ mistakes, they can watch a rewarded ad to reset their mistake counter to 0. Limited to N uses per level (default 1). NOT the same as "continue after lose" (which fires post-game-over).

---

## When Available

| Condition | Available? |
|-----------|-----------|
| `mistakeCount > 0` AND `gamePhase == .playing` | Yes |
| `mistakeCount == 0` | No (nothing to reset) |
| `gamePhase == .lost` | No (use existing "continue after lose" flow) |
| `gamePhase == .paused` / `.won` / `.needsHintAd` | No |
| `mistakeResetUsesThisLevel >= config.mistakeResetUsesPerLevel` | No (limit reached) |
| `isAdsRemoved == true` | Auto-grant (no ad shown, but still counts toward limit) |
| `config.mistakeResetEnabled == false` | No (feature disabled for this game) |

---

## New GamePhase Case

```swift
enum GamePhase: Equatable {
    case playing
    case paused
    case won
    case lost
    case needsHintAd
    case needsMistakeResetAd  // NEW
}
```

---

## ViewModel Changes

```swift
// SudokuGameViewModel — new properties
@Published var mistakeResetUsesThisLevel: Int = 0

var canResetMistakes: Bool {
    mistakeCount > 0
    && gamePhase == .playing
    && monetizationConfig.mistakeResetEnabled
    && mistakeResetUsesThisLevel < monetizationConfig.mistakeResetUsesPerLevel
}

// New methods
func requestMistakeReset() {
    guard canResetMistakes else { return }
    gamePhase = .needsMistakeResetAd
    analytics.log(.adRewardedPromptShown(reason: "mistake_reset", difficulty: puzzle.difficulty.rawValue))
}

func grantMistakeResetAfterAd() {
    mistakeCount = 0
    mistakeResetUsesThisLevel += 1
    gamePhase = .playing
    scheduleAutoSave()
    analytics.log(.mistakeResetUsed(
        difficulty: puzzle.difficulty.rawValue,
        usesThisLevel: mistakeResetUsesThisLevel
    ))
}

func cancelMistakeResetAd() {
    gamePhase = .playing
}
```

**Reset on new level:** `restart()` and init set `mistakeResetUsesThisLevel = 0`.

---

## Interaction with Game Over

```
Mistakes: 0 -> 1 -> 2 (can reset) -> 3 = LOST
                                         |
                                    Continue After Lose (existing)
                                    (sets mistakes to limit-1 = 2)
```

- Mistake reset is **during gameplay** (preventive, before game over)
- Continue after lose is **post game over** (recovery, after game over)
- Both use rewarded ads but serve different purposes
- Both are tracked separately in analytics

---

## UI Integration

Add a "Reset Mistakes" button to the game screen. Options:

**Option A (Recommended): Floating button near mistake counter**
- Appears only when `canResetMistakes == true`
- Small pill button: "Reset [ad icon]" next to mistake display (e.g., "2/3 [Reset]")
- Tapping shows the rewarded ad prompt (same pattern as hint ad)

**Option B: Toolbar button**
- Add to toolbar alongside undo/eraser/pencil/hint
- Visually disabled when not available

Go with Option A to avoid toolbar overcrowding.

```swift
// In SudokuGameView stats bar area
if viewModel.canResetMistakes {
    Button(action: { viewModel.requestMistakeReset() }) {
        Label("Reset", systemImage: "arrow.counterclockwise")
            .font(.caption)
    }
    .buttonStyle(.bordered)
    .tint(.orange)
}
```

---

## Rewarded Ad Flow (same as hints)

```
User taps "Reset Mistakes"
  -> gamePhase = .needsMistakeResetAd
  -> Show prompt: "Watch a short video to reset your mistakes?"
     -> [Watch Ad] -> AdsService.showRewardedAd()
        -> completion(true) -> grantMistakeResetAfterAd()
        -> completion(false) -> cancelMistakeResetAd()
     -> [Cancel] -> cancelMistakeResetAd()
     -> [Buy Remove Ads] (if not purchased) -> StoreService flow
```

---

## State Persistence

Add `mistakeResetUsesThisLevel` to `SudokuGameState`:

```swift
struct SudokuGameState: Codable {
    // existing fields...
    var mistakeResetUsesThisLevel: Int = 0 // NEW — defaults to 0 for backward compat
}
```

Saved with auto-save. Restored on resume. Reset to 0 on `restart()`.

---

## Files to Modify

| File | Change |
|------|--------|
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Add `mistakeResetUsesThisLevel`, `canResetMistakes`, `requestMistakeReset()`, `grantMistakeResetAfterAd()`, `cancelMistakeResetAd()`; reset counter in `restart()` |
| `Games/Sudoku/Views/SudokuGameView.swift` | Add mistake reset button near mistake counter; add `.needsMistakeResetAd` prompt |
| `Games/Sudoku/Models/SudokuGameState.swift` | Add `mistakeResetUsesThisLevel` field |
| `SharedServices/Analytics/AnalyticsEvent+Ads.swift` | Add `mistakeResetUsed` event (Phase 06 detail, but type added here) |

---

## Acceptance Criteria

- [ ] Watching rewarded ad resets `mistakeCount` to 0 immediately
- [ ] Reset limited to 1 use per level (configurable via `MonetizationConfig`)
- [ ] Button hidden when `mistakeCount == 0` or limit reached
- [ ] NOT available when `gamePhase == .lost` (different flow)
- [ ] `mistakeResetUsesThisLevel` persists via auto-save
- [ ] Counter resets to 0 on new level / restart
- [ ] IAP Remove Ads: auto-grants reset without showing ad (still counts toward limit)
- [ ] Analytics event fires with difficulty and usage count

## Tests

- Unit: `canResetMistakes` true when mistakes>0, playing, uses<limit
- Unit: `canResetMistakes` false when mistakes==0
- Unit: `canResetMistakes` false when uses>=limit
- Unit: `grantMistakeResetAfterAd()` sets `mistakeCount=0`, increments uses
- Unit: `restart()` resets `mistakeResetUsesThisLevel` to 0
- Unit: `SudokuGameState` encodes/decodes `mistakeResetUsesThisLevel`
- Manual: button appears/disappears correctly during gameplay
