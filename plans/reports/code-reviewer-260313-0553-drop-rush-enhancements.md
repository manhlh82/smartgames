# Code Review — Drop Rush Enhancements
Date: 2026-03-13

## Scope
- Files: 13 (engine, models, views, viewmodel, GameCenterService)
- New files: LevelDefinitions, LevelConfig/SpeedPhase, DropRushGameState, SpawnScheduler, HitEffect, HitEffectView, DropRushHUDView, FallingItemView
- Modified: DropRushGameViewModel (+Actions), DropRushGameView, DropRushLobbyView, GameCenterService
- Scout: checked objectInDanger + grounded path, burst lane dedup, Task lifetimes, particle animation

## Overall Assessment
Solid architecture: pure engine, config-driven levels, clean state machine. Issues found are medium/low severity; no critical security or data-loss problems.

---

## Critical Issues
None.

---

## High Priority

### 1. `objectInDanger` emitted for objects that are about to be grounded (same tick)
**File:** `DropRushEngine.swift` lines 43–45 (step 3) vs lines 48–54 (step 4)

Danger events fire before grounded objects are removed. An object at `normalizedY >= 1.0` will emit `objectInDanger` AND `objectMissed` in the same tick. The ViewModel plays no SFX for `objectInDanger`, so this is benign now — but if a consumer ever adds danger SFX it will play on objects already counted as missed.

Fix: filter out already-grounded objects in the danger loop:
```swift
for obj in state.fallingObjects where obj.normalizedY > 0.85 && obj.normalizedY < 1.0 {
    events.append(.objectInDanger(id: obj.id))
}
```

### 2. Burst spawn: second object can collide with first in same lane
**File:** `SpawnScheduler.swift` lines 24–33

`makeObject` calls `pickLane` which avoids only `lastLane` (the lane used before this batch). After `first` is created, `lastLane` is updated to first's lane. When `second = makeObject(...)` is called, `pickLane` will avoid first's lane — so in practice lanes are usually different. **However**, when `laneCount == 1` (edge case: level with 1 lane), both objects are forced to lane 0. More importantly, with `laneCount == 2`, `pickLane` avoids last lane but `available` after removing `lastLane` has exactly 1 option, so second always picks the remaining lane — fine. The real risk is `laneCount >= 3`: if the first object happened to use the same lane as the previous-batch `lastLane`, `pickLane` for the second call starts from a fresh `available` that excludes first's lane, so divergence is guaranteed. **Confirmed safe for laneCount >= 2**.

Minor: when `laneCount == 1`, burst can still fire (both objects land on lane 0 simultaneously). Add guard:
```swift
if remainingAfterFirst > 0 && screenRoomAfterFirst > 0 && config.laneCount > 1 {
```

### 3. `showSpeedUpFlash` Task not cancelled on `retry()`
**File:** `DropRushGameViewModel.swift` line 188 sets `showSpeedUpFlash = false` but the outstanding `Task` from `triggerSpeedUpFlash()` is not stored or cancelled. After retry, the orphan task can flip `showSpeedUpFlash = true` 1.5 s into the new countdown.

Fix: store the task reference and cancel in `retry()`:
```swift
private var speedUpFlashTask: Task<Void, Never>?

private func triggerSpeedUpFlash() {
    speedUpFlashTask?.cancel()
    showSpeedUpFlash = true
    speedUpFlashTask = Task { @MainActor in
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        showSpeedUpFlash = false
    }
}

func retry() {
    speedUpFlashTask?.cancel()
    // ... existing reset
}
```

---

## Medium Priority

### 4. `hitEffects` Tasks not cancelled on `retry()`
**File:** `DropRushGameViewModel.swift` line 188

`retry()` clears `hitEffects = []` synchronously, which is correct. Orphan cleanup Tasks from `spawnHitEffect` will try to `removeAll { $0.id == effectId }` ~500 ms later — since the array was already cleared, no crash, no UI artifact. Low actual risk, but storing tasks in a `[Task]` and cancelling them in `retry()` would be clean.

### 5. HitEffectView particle offset does NOT animate correctly
**File:** `HitEffectView.swift` lines 19, 30–33

`particleOffset(index:expanded:)` receives `expanded: animate` but `animate` is captured at view evaluation time, not inside the `withAnimation` block. The offset calculation is a pure function called during layout — SwiftUI cannot interpolate it. The particles will snap to their final positions while only `opacity` and `scaleEffect` animate smoothly.

Fix: make offset driven by an `@State` distance variable, or inline the offset as a modifier on a separate state:
```swift
.offset(x: animate ? CGFloat(cos(angle)) * 28 : 0,
        y: animate ? CGFloat(sin(angle)) * 28 : 0)
```
where `angle` is computed inline per particle, so SwiftUI can animate the literal `x`/`y` values.

### 6. Combo logic: `comboMultiplier` emits no event after update
**File:** `DropRushEngine.swift` line 121 (after multiplier update, before scoring)

`comboCount` and `comboMultiplier` are updated in `handleTap` but `GameEvent.comboChanged` is never emitted. The HUD reads directly from `engineState.comboCount` so the combo badge works, but any future SFX/haptic response to combo milestones has no hook. Low risk now; worth adding the event.

### 7. `symbolsForLevel` has an unreachable `default` branch
**File:** `LevelDefinitions.swift` lines 96–107

The switch covers `1...2`, `3...9`, `10...19`, `20...24`, `25...34`, `35...44`, `45...47`, `48...`, and then `default`. The `48...` case uses `...` (half-open infinite range) so default is unreachable. Safe but dead code — remove the `default` case or use it as the `48...` case directly.

---

## Low Priority

### 8. HUD hearts hardcoded to 3
**File:** `DropRushHUDView.swift` line 39: `ForEach(0..<3, id: \.self)`

If `LevelConfig` ever gives more or fewer lives, the heart display won't match. Derive from config or from `EngineState.livesRemaining` max (currently always 3, but fragile).

### 9. `laneCount` vs `symbolPool.count` mismatch potential
**File:** `LevelConfig.swift` line 85, `LevelDefinitions.swift` lines 36–69

`LevelConfig.init` takes `laneCount` as an override; `LevelDefinitions` passes `laneCountForLevel` which is independent of `symbolPool`. For levels 1–5, `symbolPool` = 2–3 symbols but `laneCount` = 3. This is intentional (wider field than symbol count), but the comment on `LevelConfig.laneCount` says "buttons in input bar = symbolPool.count" — that comment is wrong. Minor documentation issue.

### 10. File size: two files exceed 200 lines
- `DropRushGameViewModel.swift`: 235 lines
- `DropRushGameView.swift`: 238 lines

`DropRushGameView` could extract `phaseOverlays` into a dedicated `DropRushPhaseOverlaysView`. The ViewModel is borderline — the persistence helpers (~20 lines) could move to an extension file.

---

## Sudoku Regressions
No Sudoku regressions. The only Sudoku-touching diff adds `audioConfig` injection to `SudokuModule` — additive, no existing call sites changed.

---

## Edge Cases Found by Scout

- `objectInDanger` + immediate ground (same tick) — documented in issue 1 above
- Burst spawn, `laneCount == 1` — both objects on lane 0, documented in issue 2
- `showSpeedUpFlash` orphan Task after retry — documented in issue 3
- `handleTap` called while `phase != .playing` — correctly guarded at line 149

---

## Positive Observations

- Engine is pure Swift/Foundation — no UIKit/SwiftUI, excellent testability
- `SpawnScheduler` mutation is correctly `mutating` on a `struct` — no shared-state hazard
- `trySpawn` `maxOnScreen` guard is correct: `onScreenCount < config.maxOnScreen` before spawning; burst checks `screenRoomAfterFirst > 0` — burst never exceeds cap
- `TapResult.hit` pattern match in ViewModel is complete: both `.hit` and `.noTarget` are handled
- `handleTap` guard (`phase == .playing`) prevents input during countdown/ad/gameover
- `requestContinue` limited to once per attempt via `continueUsedThisAttempt` — correct
- `GameCenterService.submitScore(_:leaderboardID:)` properly guards `score > 0`, preventing zero submissions
- `retry()` clears `hitEffects`, `showSpeedUpFlash`, and cancels `countdownTask` — mostly clean
- Level definitions are config-driven via interpolation — no 50 hardcoded structs

---

## Recommended Actions (Priority Order)

1. **[High]** Guard `objectInDanger` to exclude `normalizedY >= 1.0` objects (issue 1)
2. **[High]** Store and cancel `speedUpFlashTask` in `retry()` (issue 3)
3. **[Medium]** Fix `HitEffectView` particle offset animation — use inline `x`/`y` values so SwiftUI interpolates them (issue 5)
4. **[Medium]** Add `laneCount > 1` guard to burst spawn (issue 2)
5. **[Low]** Remove unreachable `default` in `symbolsForLevel` (issue 7)
6. **[Low]** Derive HUD heart count from config, not hardcoded 3 (issue 8)

---

## Metrics
- Type coverage: full — all public APIs typed, no `Any` usage in reviewed files
- Linting: no obvious issues; one unreachable branch (issue 7)
- File size violations: 2 files (235, 238 lines; threshold 200)

## Unresolved Questions
- Are `hitEffects` Tasks (issue 4) intended to be fire-and-forget? If so, document that assumption.
- Does `comboChanged` event need to be emitted for planned SFX expansion, or is the HUD observation sufficient long-term?
