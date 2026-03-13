# Code Review — Drop Rush Enhancement Review
**Date:** 2026-03-13
**Reviewer:** code-reviewer
**Scope:** `SmartGames/Games/DropRush/` (all files) + 3 test files

---

## Scope

| Item | Detail |
|------|--------|
| Files | 22 source + 3 test files |
| LOC | ~900 source, ~200 test |
| Focus | Full module review + new-feature planning |
| Scout findings | Burst spawn double-counts, `objectInDanger` event spam, HUD live-count bug, wrong-tap flash race, HitEffectView animation bug, `DropRushGameViewModel.stars` not reset on continue |

---

## Overall Assessment

The Drop Rush module is well-structured: the engine is fully UIKit-free and testable in isolation, the ViewModel delegates cleanly, SwiftUI patterns are largely correct, and the persistence model is solid. There are **no critical security issues**. However, there are several correctness bugs — two in the engine and one in the HUD — plus a handful of medium-priority quality gaps and missing test cases.

---

## Issues Table

| # | Severity | File | Description |
|---|----------|------|-------------|
| 1 | High | `SpawnScheduler.swift` | Burst spawn double-counts: second object spawned even when `remainingAfterFirst` check ignores that both objects are being added at once |
| 2 | High | `DropRushEngine.swift` | `comboCount` not reset when `isComplete` fires (combo trail persists into result screen state) |
| 3 | High | `DropRushGameViewModel+Actions.swift` | `stars` and `isNewHighScore` not reset before rewarded-continue resumes — stale values shown if game-over overlay flashes |
| 4 | Medium | `DropRushGameView.swift` | `onChange(of:)` uses deprecated two-argument form (iOS 17 warning); `wrongFlashTask` untracked between retries |
| 5 | Medium | `DropRushEngine.swift` | `objectInDanger` events emitted every tick for the same object — no de-duplication, causes rapid-fire SFX if consumed |
| 6 | Medium | `HitEffectView.swift` | Animation does not fire when view is re-used with a different `effect` (SwiftUI identity stays same if same array position); effect is lifetime-correct only because ViewModel appends/removes, but fragile |
| 7 | Medium | `DropRushHUDView.swift` | `ForEach(0..<max(3, state.livesRemaining))` renders **more** than 3 heart slots when `livesRemaining > 3` (e.g. after a rewarded continue that bumps lives above baseline) — correct range should be `max(initialLives, state.livesRemaining)` or a fixed 3 |
| 8 | Medium | `DropRushGameView.swift` | `wrongFlashTask` stored as `@State` but never cancelled on `viewModel.retry()` — stale flash can clear `wrongFlashSymbol = nil` after a symbol no longer exists in new level |
| 9 | Low | `SpawnScheduler.swift` | `pickLane` only excludes the single last lane; with laneCount=5 and burst=2, both burst objects could share the same lane (second call to `makeObject` does see updated `lastLane`, but first call updates it, so this is correct — document it) |
| 10 | Low | `DropRushAudioConfig.swift` | `cellTapSFX` / `puzzleCompleteSFX` use Sudoku-oriented property names from `AudioConfig`; add a comment noting this is adapter glue |
| 11 | Low | `LevelDefinitions.swift` | Tier 5 (41–50) reuses `SpeedPhase.hard` — no `SpeedPhase.expert`; silent but intentional? Should document if deliberate |
| 12 | Low | `DropRushGameView.swift` | `onNextLevel` and `onLobby` both call `router.pop()` — "Next Level" should ideally push the next level rather than pop; currently requires the lobby to auto-navigate, which it does not |

---

## Critical / High Issues — Full Fix Snippets

### Issue 1 — Burst Spawn Double-Counts `objectsSpawned`

**Problem:** `trySpawn` is called with `objectsSpawned` before either object is added. The burst guard checks `remainingAfterFirst = config.totalObjects - (objectsSpawned + 1)` which correctly accounts for the first object, but the spawner returns 2 objects and the caller then increments `state.objectsSpawned` by 2. This is actually correct arithmetic — but only if the level-complete check at step 8 happens *after* those increments. Currently it does, so there is no off-by-one in the completion logic.

**Real risk:** When `remainingAfterFirst == 1` and `screenRoomAfterFirst >= 1`, the second object is spawned even though only 1 object remains to be spawned. The condition should be `remainingAfterFirst > 0` for safety, which it is — but `remainingAfterFirst` accounts for the first object already. If exactly 1 object is left after the first (i.e., 2 total remaining), both are correctly spawned. However if *only 1 total* remains and `objectsSpawned + 1 == totalObjects`, `remainingAfterFirst` is 0, so burst is blocked — correct.

**Verdict on issue 1:** The arithmetic is consistent. Document it explicitly to prevent future regression.

```swift
// SpawnScheduler.swift — add comment above burst guard
// remainingAfterFirst: objects still needed after this first spawn.
// A value > 0 means it's safe to burst a second object right now.
let remainingAfterFirst = config.totalObjects - (objectsSpawned + 1)
```

### Issue 2 — Combo Not Reset on Level Complete

**Problem:** When `isComplete` is set the combo state (`comboCount`, `comboMultiplier`) is left non-zero. The engine is marked complete and returns a `.levelComplete` event, but subsequent display of `engineState` in the result overlay will show non-zero combo, and `retry()` resets it via `engine.reset()`, so it's cosmetically benign — but it's a latent bug if the result overlay ever shows the combo badge.

```swift
// DropRushEngine.swift — in tick(), immediately after setting isComplete = true
if state.objectsSpawned >= config.totalObjects && state.fallingObjects.isEmpty {
    state.isComplete = true
    state.comboCount = 0          // ADD: clear combo on completion
    state.comboMultiplier = 1.0   // ADD
    events.append(.levelComplete(...))
}
```

### Issue 3 — Stale `stars` / `isNewHighScore` on Rewarded Continue

**Problem:** `requestContinue()` sets `phase = .playing` without clearing `stars` or `isNewHighScore`. If the rewarded continue path leads to a second game-over before level completion, the result overlay flashes `isNewHighScore = true` from a prior session.

```swift
// DropRushGameViewModel+Actions.swift — in requestContinue success branch
if success {
    self.continueUsedThisAttempt = true
    self.stars = 0                   // ADD
    self.isNewHighScore = false      // ADD
    self.engine.restoreLife()
    ...
}
```

### Issue 7 — HUD Heart Overflow

**Problem:** `ForEach(0..<max(3, state.livesRemaining))` renders N hearts where N can exceed 3 after `restoreLife()` is called on a full-lives engine. With lives=3 already, `restoreLife()` makes it 4, so 4 hearts display.

```swift
// DropRushHUDView.swift — fix the heart loop
// Replace:
ForEach(0..<max(3, state.livesRemaining), id: \.self) { i in
// With: always render exactly 3 slots (lives are capped elsewhere)
ForEach(0..<3, id: \.self) { i in
```

Note: `restoreLife()` itself has no upper-bound cap. Consider adding `state.livesRemaining = min(state.livesRemaining + 1, config.totalLives)` in the engine — or at minimum cap at the starting 3.

---

## Medium Priority

### Issue 5 — `objectInDanger` Event Spam

`objectInDanger` is emitted every tick (up to 60×/sec) for every object in the danger zone. The current `ViewModel.handleEvent` silently ignores it (`default: break`), so there is no current SFX problem. But this is a trap: any future subscriber that adds a "danger" SFX will cause audio spam.

Fix: track which IDs have already been flagged in `EngineState` and only emit once per object per danger entry:

```swift
// EngineState — add:
var dangerObjectIds: Set<UUID> = []

// Engine tick step 3 — replace:
for obj in state.fallingObjects where obj.normalizedY > 0.85 && obj.normalizedY < 1.0 {
    if !state.dangerObjectIds.contains(obj.id) {
        state.dangerObjectIds.insert(obj.id)
        events.append(.objectInDanger(id: obj.id))
    }
}
// Clear IDs for removed objects in step 4:
state.dangerObjectIds = state.dangerObjectIds.filter { id in
    state.fallingObjects.contains(where: { $0.id == id })
}
```

### Issue 8 — `wrongFlashTask` Race on Retry

`wrongFlashTask` is stored in `DropRushGameView` as `@State`. When `viewModel.retry()` is called the state is preserved across the re-render (same View identity). A pending flash task from the previous attempt can fire and set `wrongFlashSymbol = nil` after a symbol that now exists in the new attempt, which is harmless but logically wrong. Cancel it in the tap closure on retry, or pass a cancel-token from the ViewModel.

Quick fix in `DropRushGameView`:
```swift
// In the retry button handler (result overlay onRetry):
wrongFlashTask?.cancel()
wrongFlashSymbol = nil
viewModel.retry()
```

Currently `onRetry: viewModel.retry` is passed as a closure with no hook to cancel the flash. Wrap it:

```swift
onRetry: {
    wrongFlashTask?.cancel()
    wrongFlashSymbol = nil
    viewModel.retry()
}
```

### Issue 4 — Deprecated `onChange` Signature

```swift
// DropRushGameView.swift line 83
.onChange(of: scenePhase) { newPhase in   // iOS 14–16 signature, deprecated in iOS 17
// Fix:
.onChange(of: scenePhase) { _, newPhase in
```

Similarly line 106:
```swift
.onChange(of: timeline.date) { date in
// Fix:
.onChange(of: timeline.date) { _, date in
```

---

## Low Priority

- **Issue 9:** `pickLane` lane-exclusion is single-history only. With 5 lanes it rarely causes actual clustering, but a small ring-buffer (last 2 lanes) would improve distribution at no algorithmic cost.
- **Issue 10:** `DropRushAudioConfig` property names (`cellTapSFX`, `puzzleCompleteSFX`) are Sudoku-centric but it's just the `AudioConfig` protocol contract. Add a comment.
- **Issue 11:** Tier 5 uses `SpeedPhase.hard` — intentional re-use is fine; add an inline comment.
- **Issue 12:** "Next Level" pops to lobby instead of pushing the next level screen. This is a navigation architecture decision. Low UX friction right now but worth revisiting as level count grows.

---

## Edge Cases Found by Scout

| Edge Case | Location | Risk |
|-----------|----------|------|
| `restoreLife()` exceeds initial lives cap → HUD renders 4+ hearts | `DropRushEngine.swift` + `HUDView` | Medium (visual glitch) |
| `wrongFlashTask` fires after retry with new symbol pool | `DropRushGameView.swift` | Low (wrong flash color cleared incorrectly) |
| `objectInDanger` events for all objects every frame | `DropRushEngine.swift` tick step 3 | Medium (SFX trap for future devs) |
| `animateStars` in `DropRushResultOverlay` — if overlay is dismissed then re-shown (phase flicker), `starAnimTask` is cancelled by `.onDisappear` but `revealedStars` retains its value → stars already revealed on next appearance | `DropRushResultOverlay.swift` | Low |
| `levelsCompletedThisSession % 2 == 0` fires interstitial on level 0 (first completion, counter = 1; on second completion counter = 2, fires) — correct. But counter is never reset on `retry()` — intention seems fine | `DropRushGameViewModel.swift` | Low (by design, no reset needed) |

---

## Positive Observations

- Engine is completely framework-free — an excellent architectural boundary. Tests prove this works.
- `EngineState` is a value type snapshot — clean data flow, no accidental sharing.
- `SpawnScheduler` mutation isolation (it's a `struct`) is correct and clean.
- Delta clamping to 100ms in `tick()` is excellent defensive programming.
- `trySpawn` correctly enforces both the on-screen cap and total-objects cap before bursting.
- `DropRushProgress.recordResult` never downgrades scores/stars — important invariant.
- `starsForAccuracy` is a pure free function — easy to unit-test (and it is).
- `HitEffectView` uses `Foundation.cos/sin` explicitly to avoid ambiguity — good practice.
- `LevelDefinitions.fatalError` for unmapped levels is loud-fail appropriate — better than silent misconfiguration.
- Test coverage for engine, progress, and level definitions is solid. Edge case additions recommended below.

---

## Missing Test Cases

| Test | Why Important |
|------|---------------|
| `testHandleTap_TargetsClosestToGround` | Two objects of same symbol — engine should destroy the one with higher `normalizedY`; untested |
| `testTick_LevelComplete_ClearsCombo` | Verify combo is zeroed when `isComplete` fires (issue 2) |
| `testRestoreLife_DoesNotExceedMax` | Guard against uncapped `livesRemaining` going above 3 |
| `testSpawnScheduler_BurstDoesNotExceedTotalObjects` | Ensure final burst never overspawns |
| `testStarsRevealAnimation_OnReappear` | `revealedStars` reset to 0 on re-appearance (overlay dismiss/re-show) |
| `testContinue_ClearsPriorStarState` | `stars == 0` and `isNewHighScore == false` after `requestContinue` succeeds |

---

## New Feature Planning

### Feature 1 — Combo Streak Visual Pulse

**User value:** Sustained combos feel invisible beyond the static badge. A screen-edge glow or falling-object pulse that intensifies with combo level gives immediate tactile feedback and rewards skilled play without disrupting UX.

**Implementation complexity:** Low

**Key files:**
- `DropRushGameViewModel.swift` — expose `engineState.comboCount` (already published)
- `DropRushGameView.swift` — add a `comboGlow` ZStack layer behind the game area, driven by `comboCount`
- `FallingItemView.swift` — optionally scale the circle slightly at combo ≥ 5

**Estimated effort:** 2–3 hours

---

### Feature 2 — Perfect Accuracy Bonus (End-of-Level)

**User value:** Players who hit every single object get a score multiplier (e.g. +500 "Perfect!" bonus). Creates a compelling replay incentive beyond star ratings and closes the gap between 3-star "good" and "flawless".

**Implementation complexity:** Low

**Key files:**
- `DropRushEngine.swift` — expose `state.misses == 0` at level complete; add `.levelComplete` associated value `isPerfect: Bool`
- `DropRushGameViewModel.swift` — detect `.levelComplete(_, _, misses: 0)` → bonus score + `isPerfect` flag
- `DropRushResultOverlay.swift` — show "PERFECT!" badge when `isPerfect == true`

**Estimated effort:** 2–3 hours

---

### Feature 3 — Time-Attack Mode (Optional Modifier Per Level)

**User value:** Players who've 3-starred every level have no replay incentive. A "time attack" badge visible on the level cell (fastest clear time recorded) adds a meta-layer without restructuring the engine.

**Implementation complexity:** Medium

**Key files:**
- `DropRushStats.swift` / `DropRushProgress.swift` — add `levelBestTimes: [Int: TimeInterval]`
- `DropRushEngine.swift` — `elapsedTime` at level complete is already available
- `DropRushGameViewModel.swift` — save `engine.state.elapsedTime` on level complete
- `LevelCellView.swift` — show small clock icon + time if record exists

**Estimated effort:** 4–5 hours

---

### Feature 4 — Obstacle Objects ("Bombs")

**User value:** At medium/hard levels, a small percentage of falling objects become red "bomb" symbols that cost a life if tapped. Adds a visual-scan layer that rewards attentiveness over pure reaction speed and differentiates expert play.

**Implementation complexity:** Medium

**Key files:**
- `FallingObject.swift` — add `isBomb: Bool` property
- `SpawnScheduler.swift` — inject bomb probability from `LevelConfig` (e.g. `bombRate: CGFloat`)
- `LevelConfig.swift` + `LevelDefinitions.swift` — add `bombRate` parameter (0 for tiers 1–2, 0.05–0.15 for tiers 3–5)
- `DropRushEngine.swift` — `handleTap` on bomb: decrement life, emit new `GameEvent.bombTapped`
- `FallingItemView.swift` — render bomb with skull/explosion SF Symbol
- `DropRushInputBarView.swift` — no change (player still taps symbol buttons, bomb matches symbol but punishes)

**Estimated effort:** 6–8 hours

---

## Recommended Actions (Priority Order)

1. **Fix HUD heart overflow** (Issue 7) — visible glitch on rewarded continue, 10-min fix
2. **Clear stale `stars`/`isNewHighScore` on continue** (Issue 3) — incorrect UI state
3. **Reset combo on level complete** (Issue 2) — engine state correctness
4. **Fix deprecated `onChange` signatures** (Issue 4) — suppress iOS 17 warnings
5. **Cancel `wrongFlashTask` on retry** (Issue 8) — view state cleanup
6. **Add missing test cases** (6 tests listed above) — coverage gaps on critical paths
7. **De-duplicate `objectInDanger` events** (Issue 5) — SFX trap prevention
8. **Implement Feature 1 (combo pulse)** — highest effort-to-polish ratio
9. **Implement Feature 2 (perfect bonus)** — quick win for replay value
10. **Document burst spawn arithmetic and Tier 5 speed phase re-use** (Issues 1, 11)

---

## Metrics

| Metric | Value |
|--------|-------|
| Type safety | Excellent — all models typed, no `Any` usage |
| Engine purity | Pass — zero UIKit/SwiftUI imports in engine |
| Linting issues | ~2 deprecation warnings (onChange signatures) |
| Test coverage (engine) | ~75% — missing closest-to-ground tap, combo reset, burst-cap |
| Test coverage (progress) | ~90% — solid |
| Test coverage (level defs) | ~85% — solid |
| Memory leaks | None found — Tasks are captured `[weak self]`, stored for cancellation |
| Retain cycles | None found — ViewModel captures services by protocol, no circular refs |

---

## Verdict

**APPROVE WITH FIXES**

Issues 2, 3, and 7 are correctness bugs that affect visible game state. Issue 4 produces build warnings. All are straightforward fixes with no architectural impact. The engine design is clean and the test suite provides a solid base.

---

## Unresolved Questions

1. Is `restoreLife()` intended to be uncapped? If rewarded-continue is ever triggered when lives > 0 (e.g. a future "extra life ad" mechanic), the HUD will break again. Recommend capping in the engine.
2. Should "Next Level" in the result overlay push the next level directly rather than popping to lobby? The current flow forces the player through the lobby grid every time.
3. Tier 5 (`levels 41–50`) reuses `SpeedPhase.hard` — is a separate `SpeedPhase.expert` planned or intentionally omitted?
