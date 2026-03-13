# Code Review — Drop Rush Phase 04 Gameplay UI

**Date:** 2026-03-12
**Scope:** Phase 04 new files + DropRushModule.swift wiring
**Reviewer:** code-reviewer agent

---

## Scope

| File | LOC |
|------|-----|
| DropRushGameViewModel.swift | 161 |
| DropRushGameView.swift | 173 |
| FallingItemView.swift | 43 |
| DropRushInputBarView.swift | 53 |
| DropRushHUDView.swift | 65 |
| DropRushPauseOverlay.swift | 43 |
| DropRushResultOverlay.swift | 109 |
| DropRushModule.swift (modified) | 53 |

All files within the 200-line limit per code standards.

---

## Overall Assessment

Solid implementation. State machine is straightforward, engine isolation is clean, and the TimelineView game loop pattern is correct. Four issues worth fixing before shipping: one correctness bug in the wrong-tap flash, one countdown race condition, one non-@MainActor Task mutation concern, and one UI guard missing on the HUD pause button.

---

## Critical Issues

None.

---

## High Priority

### H1 — Wrong-tap flash is broken: `wrongTaps` counter comparison races with ViewModel update

**File:** `DropRushGameView.swift` lines 46–53
**Problem:** The flash logic reads `engineState.wrongTaps` *before* calling `viewModel.handleTap`, then compares to the post-call value. Because `handleTap` is synchronous and `@MainActor`, this works for the counter — but `wrongTaps` in `EngineState` increments for *every* no-target tap. The flash fires correctly, but the comparison `viewModel.engineState.wrongTaps > before` relies on `wrongTaps` being a monotone counter, not a per-symbol signal. **The real problem:** `DropRushInputBarView` has a `flash(symbol:)` method that is never called. The flash is driven by `wrongFlashSymbol` in `DropRushGameView`, but that state is never passed *into* `DropRushInputBarView` — the bar has its own `flashSymbol: String? @State` but receives no binding, so it never flashes red.

**Impact:** Wrong-tap visual feedback is silently broken. The button never turns red.

**Fix options:**
1. Pass `wrongFlashSymbol` as a binding or parameter to `DropRushInputBarView` and drive `flashSymbol` from there.
2. Or keep flash state entirely in `DropRushGameView`, remove the dead `flash(symbol:)` / `flashSymbol` from `DropRushInputBarView`, and overlay a red flash on the input bar externally.

The `triggerFlashIfNeeded` stub in `DropRushInputBarView` (lines 50–52) should be removed — it's dead code.

---

### H2 — Countdown Task writes `@Published` from off-actor context

**File:** `DropRushGameViewModel.swift` lines 63–71
**Problem:**

```swift
countdownTask = Task { [weak self] in
    for count in stride(from: 3, through: 1, by: -1) {
        guard let self, !Task.isCancelled else { return }
        self.countdownValue = count
        try? await Task.sleep(nanoseconds: 900_000_000)
    }
    guard let self, !Task.isCancelled else { return }
    self.phase = .playing
}
```

`Task { }` without explicit actor context inherits the *calling* actor context only if the enclosing scope is isolated. Since `startCountdown()` is called from `init` (which does run on MainActor via `@MainActor final class`), this Task *should* hop to MainActor. However, the `[weak self]` capture means after the first `await`, the actor isolation guarantee via `self` is weakened — Swift 5.9 will warn or error here in strict concurrency. The pattern is safe today but fragile.

**Recommended fix:** Annotate the task closure explicitly:

```swift
countdownTask = Task { @MainActor [weak self] in
```

This makes actor isolation explicit and eliminates any ambiguity under strict concurrency checking.

---

### H3 — Countdown shows "GO!" but `countdownValue` never reaches 0

**File:** `DropRushGameView.swift` line 162 / `DropRushGameViewModel.swift` lines 64–70
**Problem:** The stride runs `3, 2, 1` — it never sets `countdownValue = 0`. The countdown overlay shows `"\(viewModel.countdownValue > 0 ? "\(viewModel.countdownValue)" : "GO!")"`, so "GO!" requires `countdownValue == 0`. But the task sets `countdownValue = 3, 2, 1` then transitions `phase = .playing` immediately. The view shows "3... 2... 1..." but never "GO!" because the overlay disappears (`phase != .countdown`) before `countdownValue` could reach 0.

**Impact:** Minor UX — "GO!" never shows. The spec calls it out as a feature.

**Fix:** After the stride loop, set `countdownValue = 0` and add a brief sleep before transitioning to `.playing`:

```swift
self.countdownValue = 0
try? await Task.sleep(nanoseconds: 400_000_000)
guard !Task.isCancelled else { return }
self.phase = .playing
```

---

## Medium Priority

### M1 — HUD pause button accessible during countdown and result phases

**File:** `DropRushHUDView.swift` lines 49–55
**Problem:** The pause button fires `onPause()` or `onResume()` regardless of phase. `DropRushGameViewModel.pause()` has the guard `guard phase == .playing`, so it's safe. But `onResume()` is always `viewModel.resume` — if the user taps the pause/play icon while in `.countdown` phase (the icon shows "pause.fill" since phase != .paused), `pause()` is called and correctly rejected. However the button is *visible and tappable* during `.levelComplete` / `.gameOver` — pressing it does nothing silently, which may confuse users.

**Recommended fix:** Disable the button when `phase != .playing && phase != .paused`:

```swift
.disabled(phase != .playing && phase != .paused)
.opacity(phase == .playing || phase == .paused ? 1.0 : 0.4)
```

---

### M2 — `starsForAccuracy` result can be 0 for a completed level, saved as progress

**File:** `DropRushGameViewModel.swift` lines 96–99
**Problem:** When accuracy < 60%, `starsForAccuracy` returns 0. The ViewModel calls `saveProgress(score:stars:0)`, which calls `recordResult(level:stars:0, score:)`. `recordResult` guards `if stars > previousStars`, so it won't downgrade stars. But the level *is* marked completed in `DropRushProgress` if the score improved — the lobby can show it as "completed with 0 stars", which the spec's unlock logic (`isUnlocked` requires >= 1 star on N-1) would treat as *locked*. This is a design ambiguity: can a player complete a level with 0 stars and proceed?

**Recommendation:** Clarify whether 0-star completions count as "passed" for unlock. If not, `isUnlocked` is correct as-is. Document the intent in `starsForAccuracy` or `recordResult`. No code change required if current behavior is intentional.

---

### M3 — `DropRushResultOverlay` `animateStars` uses `DispatchQueue` instead of `Task`

**File:** `DropRushResultOverlay.swift` lines 102–108
**Problem:** `DispatchQueue.main.asyncAfter` is used for star animation delays. This works but is inconsistent with the project's async/await patterns and doesn't cancel if the view disappears (e.g. user presses retry quickly). While not a crash risk (the closure captures only value types), prefer `Task` + `try? await Task.sleep` with `onDisappear` cancellation for consistency.

---

### M4 — `LevelDefinitions.level(_:)` fallback silently loads level 1 for unknown levels

**File:** `DropRushGameViewModel.swift` line 45
**Code:** `let cfg = LevelDefinitions.level(levelNumber) ?? LevelDefinitions.levels[0]`
**Problem:** If routing sends an invalid `levelNumber`, the fallback silently starts level 1 with no warning. A player deep-linked to an invalid level would see level 1 content but the HUD shows the wrong level number (`levelNumber` is stored separately from config).

**Fix:** At minimum, assert in DEBUG:

```swift
assert(LevelDefinitions.level(levelNumber) != nil, "Unknown level: \(levelNumber)")
```

---

## Low Priority

### L1 — `wrongFlashSymbol` state in `DropRushGameView` is orphaned

**File:** `DropRushGameView.swift` line 10
`@State private var wrongFlashSymbol: String?` is set but only read in the tap closure to decide whether to set itself — it is never passed to any view for display (see H1). Remove after fixing H1.

---

### L2 — HUD lives hardcoded to 3 hearts

**File:** `DropRushHUDView.swift` line 28
`ForEach(0..<3, id: \.self)` hardcodes 3 hearts. If a future `LevelConfig` sets `livesRemaining` to something other than 3, the HUD renders incorrectly. Should be driven by `state.livesRemaining` with a known `maxLives` (from config or a constant). Low priority since all current levels use 3 lives.

---

### L3 — `DropRushGameView` `onChange(of: scenePhase)` uses deprecated two-argument closure (iOS 17+)

**File:** `DropRushGameView.swift` line 71
```swift
.onChange(of: scenePhase) { phase in
```
The single-value closure form is deprecated in iOS 17. Prefer:
```swift
.onChange(of: scenePhase) { _, newPhase in
```
The code targets iOS 16+, so both forms compile, but aligning with the newer signature avoids future deprecation warnings.

---

### L4 — `DropRushInputBarView.flash(symbol:)` is dead public API

**File:** `DropRushInputBarView.swift` lines 42–47
Public method never called externally. Remove or make private and wire up properly (see H1).

---

## Edge Cases Found by Scout

- **Rapid retry during countdown:** `retry()` cancels `countdownTask` then calls `startCountdown()` which creates a new Task. If the user taps retry very rapidly, multiple Tasks could queue up before cancellation propagates through the cooperative thread pool. The `guard !Task.isCancelled` checks are present, so old tasks self-terminate — safe, but the first tick of a new task will still run concurrently with cancellation of the old one for one iteration. Delta-time reset (`lastTickDate = nil`) in `startCountdown()` prevents position jumps.

- **Background return delta spike:** Correctly clamped at 0.1s. `lastTickDate = nil` on pause also prevents the jump. Covered.

- **Level complete event fired twice:** Engine guards `!state.isComplete` at tick entry, so the event fires exactly once. ViewModel transitions phase to `.levelComplete` on first event. Subsequent ticks no-op. Safe.

- **handleTap during countdown/levelComplete/gameOver:** `guard phase == .playing` in ViewModel correctly blocks all non-playing taps. Safe.

- **`wrongTaps` counter overflow:** Theoretical only — `Int` won't overflow in practice. Not an issue.

- **`ForEach(1...3)` in result overlay when `stars == 0`:** Range `1...3` is always valid (never empty), so no crash. `revealedStars` starts at 0 and `if i <= stars (0)` never fires — all stars remain hollow. Correct behavior.

---

## Positive Observations

- Engine is fully decoupled from UIKit/SwiftUI — excellent testability.
- `@MainActor final class` on ViewModel matches project standards.
- `StateObject(wrappedValue:)` init pattern in `DropRushGameView` is correct for injecting dependencies into `@StateObject`.
- Delta clamping (`min(max(delta, 0), 0.1)`) correctly handles both negative (clock skew) and large (background return) values.
- `lastTickDate = nil` on both `pause()` and `resume()` correctly prevents stale delta accumulation.
- `DropRushColors.palette` as a shared enum prevents color divergence between `FallingItemView` and `DropRushInputBarView`.
- `DropRushModule.navigationDestination` correctly parses the `level-N` context string.
- `DropRushProgress.recordResult` correctly uses improvement-only logic — no score downgrades.
- `starsForAccuracy` is a free function in the model layer — correctly not coupled to ViewModel.
- File sizes all under 200-line limit.

---

## Recommended Actions

1. **(H1 — Blocker for feedback correctness)** Fix wrong-tap flash: pass flash state into `DropRushInputBarView` or drive it from `DropRushGameView`. Remove dead `flash(symbol:)` and `triggerFlashIfNeeded` stubs.
2. **(H2)** Add `@MainActor` annotation to countdown Task closure for explicit actor isolation.
3. **(H3)** Set `countdownValue = 0` + 400ms delay before `phase = .playing` to show "GO!".
4. **(M1)** Disable HUD pause button during non-interactive phases.
5. **(M3)** Replace `DispatchQueue.main.asyncAfter` in `animateStars()` with `Task` + cancellation.
6. **(L2)** Drive HUD heart count from config max rather than hardcoded 3.
7. **(L3)** Update `onChange` to two-argument form.
8. **(L4)** Remove dead `flash(symbol:)` public method from `DropRushInputBarView`.

---

## Metrics

- Files reviewed: 8
- Type coverage: Good — `@Published private(set)` used correctly, engine state fully typed
- Hardcoded constants: 1 concern (heart count)
- Dead code: `triggerFlashIfNeeded`, `flash(symbol:)`, `wrongFlashSymbol` (partially)
- `DispatchQueue.main.asyncAfter` usages: 2 (both in DropRushResultOverlay + DropRushGameView tap closure)

---

## Unresolved Questions

1. Should 0-star level completions unlock the next level? Current `isUnlocked` requires >= 1 star, which means a player who beats a level with < 60% accuracy cannot advance. Is this intentional?
2. Phase 07 (rewarded continue / extra life) adds `watchingAd` to the phase enum — the current ViewModel has no `watchingAd` case. Is Phase 04 intentionally leaving this out, to be added in Phase 07?
