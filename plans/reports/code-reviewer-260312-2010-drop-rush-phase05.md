# Code Review — Drop Rush Phase 04 Bug Fixes + Phase 05 Lobby

**Date:** 2026-03-12
**Scope:** Phase 04 bug fixes (H1–H3, M1, M3) + Phase 05 lobby implementation
**Build:** SUCCEEDED

---

## Scope

**Phase 04 Bug Fix Files**
- `DropRushInputBarView.swift` — H1 flash refactor (37 lines)
- `DropRushGameView.swift` — H1 wire + flash Task (175 lines)
- `DropRushGameViewModel.swift` — H2 @MainActor countdown, H3 "GO!" display (165 lines)
- `DropRushHUDView.swift` — M1 pause button guard (67 lines)
- `DropRushResultOverlay.swift` — M3 star anim Task + cancel (115 lines)

**Phase 05 New/Modified Files**
- `DropRushLobbyViewModel.swift` — NEW (19 lines)
- `LevelCellView.swift` — NEW (41 lines)
- `DropRushLobbyView.swift` — NEW (59 lines)
- `DropRushModule.swift` — `makeLobbyView` wired (53 lines)

**Total LOC reviewed:** ~731

---

## Overall Assessment

Both the bug fixes and lobby are clean, minimal, and directly aligned with the plan spec. No syntax issues or build breakage. The main actionable concerns are a persistence-key inconsistency that is already present in the codebase, one ambiguous star-animation edge case in the result overlay, and a missing guard in the lobby navigation path.

---

## Critical Issues

None.

---

## High Priority

### H-1 — Hardcoded persistence key in `DropRushGameViewModel`

`saveProgress()` uses the raw string `"dropRush.progress"` rather than `PersistenceService.Keys.dropRushProgress`. The lobby ViewModel correctly uses the constant. The GameViewModel does not.

**File:** `DropRushGameViewModel.swift` lines 158, 162
**Risk:** Silent key mismatch if the constant is ever renamed during a migration. Currently not a runtime bug because both strings are identical, but it violates the project rule: "Never hardcode strings at call sites" (`code-standards.md`).

**Fix:**
```swift
// line 158
var progress = persistence.load(DropRushProgress.self, key: PersistenceService.Keys.dropRushProgress) ?? DropRushProgress()
// line 162
persistence.save(progress, key: PersistenceService.Keys.dropRushProgress)
```

---

### H-2 — Lobby navigation does not guard against out-of-range level numbers

`DropRushLobbyView` calls `router.navigate(to: .gamePlay(gameId: "dropRush", context: "level-\(config.levelNumber)"))` without rechecking `isUnlocked`. The cell itself is `.disabled(!isUnlocked)` so the tap action should never fire for locked levels — but that is a UI-layer guard, not a business-logic guard.

`DropRushModule.navigationDestination` then parses the level number and passes it directly to `DropRushGameViewModel.init`, which calls `LevelDefinitions.level(levelNumber) ?? LevelDefinitions.levels[0]`. The fallback (`levels[0]`) silently starts level 1 instead of failing loudly if an invalid context string arrives (e.g., a future deep-link with a bad level number).

**Risk:** Low probability at launch, but bad UX if ever hit from an external route (Phase 07 interstitial skip, push notification deep-link, etc.).

**Recommendation:** Add an explicit guard in `DropRushLobbyViewModel` (deferred `selectLevel` method) or at minimum document the fallback behaviour in `DropRushModule.navigationDestination` with a comment.

---

## Medium Priority

### M-1 — Star animation reveals only stars up to the stored count; 0-star case silently shows nothing

`animateStars()` in `DropRushResultOverlay` iterates `1...3` and only calls `revealedStars = i` when `i <= stars`. If `stars == 0` (e.g., accuracy < 60%), the task runs to completion but `revealedStars` remains 0, which is the correct visual — all stars shown as empty outlines. This is fine.

However, `revealedStars` is not reset to `0` before the task starts. If `DropRushResultOverlay` is reused/replayed (retry path goes through `DropRushGameView` re-creating the view, so this is **not** an actual issue in the current architecture), stale `revealedStars` could persist. Verify the view is always fully deallocated on retry — it is, because `retry()` changes `phase` away from `.levelComplete`, removing the overlay from the view tree. No bug, but worth noting for Phase 07 if a "watch ad to continue" keeps the overlay partially visible.

### M-2 — `DropRushLobbyViewModel.progress` is `private(set)` but re-read from disk on every `.onAppear`

The refresh reads from `UserDefaults` on the main thread synchronously. For 50 levels this is negligible, but calling `refreshProgress()` inside `.onAppear` on every navigation-back adds a small main-thread stall. Consider caching the progress object and only refreshing when a `NotificationCenter` post fires after save, or accept this as KISS-appropriate for the current scale (50 levels, lightweight JSON). No action required until performance profiling shows an issue.

### M-3 — `LevelCellView` stars always render `1...3` even when `stars == 0`

`ForEach(1...3, id: \.self)` works correctly because `i <= 0` is always false, so all three render as empty stars. This is correct. Noting it here because `ForEach(1...3, ...)` with a `stars` value of 0 is not an index-out-of-range crash in Swift, but the pattern `1...stars` would crash — the current pattern is safe.

### M-4 — `DropRushGameView` wrong-flash Task does not hold a reference; overlapping taps could clear prematurely

```swift
wrongFlashSymbol = symbol
Task { @MainActor in
    try? await Task.sleep(nanoseconds: 200_000_000)
    if wrongFlashSymbol == symbol { wrongFlashSymbol = nil }
}
```

If two wrong taps on **different** symbols arrive within 200ms (e.g., rapid accidental taps), the second task can clear `wrongFlashSymbol` early for the first symbol or leave neither highlighted. The guard `if wrongFlashSymbol == symbol` mitigates the "clear wrong symbol" case but the flash for the first symbol is still cancelled. This is an acceptable trade-off — the flash is cosmetic — but storing the task in a `@State var wrongFlashTask: Task<Void, Never>?` and cancelling it before starting a new one would make the behaviour deterministic.

---

## Low Priority

### L-1 — `DropRushModule.init(persistence:)` ignores its parameter

```swift
init(persistence: PersistenceService) {}
```

The persistence parameter is accepted but not stored. The module passes `environment.persistence` directly when creating views. This matches the pattern used elsewhere in the codebase and is intentional (stateless module), but the parameter name suggests it might have been intended for module-level state. Add a comment to clarify intent, or drop the parameter and use a no-arg `init()` (only if the `GameModule` protocol doesn't require it).

### L-2 — `sound`, `haptics`, `ads` properties on `DropRushGameViewModel` are `let` but `internal` access

Lines 29–31: these service properties are `let` (correct) but `internal` (no explicit `private`). They are only used internally in the ViewModel. No external consumer reads them directly. Consider marking them `private` for encapsulation.

### L-3 — Progress header label says "BEST SCORE" but the spec says "cumulative score"

`DropRushLobbyView` line 50 renders label "BEST SCORE" over `cumulativeHighScore`. The property name and doc comment say "sum of all per-level high scores". This is technically a "cumulative best" not a "single-run best", so the label is slightly misleading. "TOTAL SCORE" or "HIGH SCORES" would be more accurate. Low impact — subjective.

---

## Edge Cases Scouted

- **Level 1 unlock invariant:** `DropRushProgress.isUnlocked(1)` always returns `true` (hardcoded). `LevelCellView` is safe.
- **0-star completion saves correctly:** `recordResult` with `stars: 0` does not downgrade an existing `levelStars` entry because `0 > previousStars` is false when previousStars > 0. Correct — a bad run can't regress stars.
- **`LevelDefinitions.levels[0]` fallback in GameVM:** safe for invalid level number strings arriving from nav context, but silently starts level 1 (see H-2).
- **Countdown cancellation on rapid retry:** `retry()` calls `countdownTask?.cancel()` before re-starting — race-free.
- **`revealedStars` reset on `onDisappear`:** Not explicitly reset. Safe because the view is removed from tree on phase change and `@State` is destroyed. A re-appear would call `animateStars()` fresh with `revealedStars` starting at 0 again. Correct.
- **50-cell LazyVGrid memory:** trivially small; no concern.

---

## Positive Observations

- H1 fix is the right architecture — lifting flash state into the parent view as `wrongFlashSymbol: String?` is idiomatic SwiftUI and avoids `@State` in a pure-data child view.
- H2 `@MainActor` on countdown Task eliminates the main-thread actor-hopping that the bug described; clean fix.
- H3 `countdownValue = 0` + 400ms sleep gives the "GO!" moment visibility without extra view state.
- M1 pause button guard is clear and minimal — using `let isInteractive` as a local binding reads well.
- M3 `starAnimTask?.cancel()` in `onDisappear` is the correct cancellable Task pattern.
- Lobby ViewModel is exactly 19 lines — exemplary KISS/YAGNI.
- `DropRushProgress.recordResult` never downgrades — correct immutability semantics.
- All plan TODO items for Phase 05 are checked off. Phase 04 deferred items (animations, device test) correctly remain open.

---

## Recommended Actions (Prioritised)

1. **[High]** Replace hardcoded `"dropRush.progress"` strings in `DropRushGameViewModel` with `PersistenceService.Keys.dropRushProgress` (2-line change).
2. **[High]** Add comment in `DropRushModule.navigationDestination` documenting the `levels[0]` fallback and noting it is intentional defensive behaviour, not a silent bug absorber.
3. **[Medium]** Store the wrong-flash `Task` in `@State var wrongFlashTask` and cancel before starting a new one, for deterministic multi-tap behaviour.
4. **[Low]** Mark `sound`, `haptics`, `ads` as `private let` in `DropRushGameViewModel`.
5. **[Low]** Rename "BEST SCORE" label in progress header to "TOTAL SCORE" for accuracy.

---

## Plan TODO Verification

- Phase 04: all checkboxes complete. Two items deliberately deferred to Phase 08 (animations, device test) — correct.
- Phase 05: all checkboxes complete. No outstanding items.

---

## Metrics

- Type coverage: 100% (all public API is typed; no `Any` usage in reviewed files)
- Linting issues: 0 blocking; 2 style (internal service properties, hardcoded key string)
- Build: SUCCEEDED

---

## Unresolved Questions

1. Does `DropRushModule.init(persistence:)` intentionally accept-but-ignore persistence, or is it a leftover signature from an earlier design? If the `GameModule` protocol mandates this signature, add a comment; if not, consider simplifying to `init()`.
2. Phase 07 plans a "Watch Ad to Continue" button on the game-over overlay. The current `DropRushPhase` enum does not include a `watchingAd` case (the plan spec shows it). Will Phase 07 add this case, and will it require guarding the HUD pause button for that phase too (currently only guarded for `.playing`/`.paused`)?
