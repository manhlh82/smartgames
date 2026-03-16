---
title: "Drop Rush — Armored Digits (2-Tap Mechanic)"
description: "Add armored/2-tap falling objects with glowing ring visual, hit-state transitions, and correct destruction logic"
status: completed
priority: P1
effort: 4h
branch: main
tags: [drop-rush, gameplay, engine, visual, animation]
created: 2026-03-13
---

# Drop Rush — Armored Digits (2-Tap Mechanic)

## Overview

Some falling digits require 2 correct taps to destroy ("armored"). A glowing animated ring indicates an armored digit. After the first correct tap, the ring disappears and the digit continues falling — signaling only 1 more tap needed. The second correct tap destroys it normally with explosion effect.

## Phase Overview

| Phase | Focus | Effort | Status |
|-------|-------|--------|--------|
| [Phase 1](phase-01-engine-and-state-model.md) | Engine: hit-state model, tap logic, spawn probability | 2h | completed |
| [Phase 2](phase-02-visual-glow-ring.md) | Visual: glowing animated ring, first-hit transition | 2h | completed |

## Key Design Decisions

- `FallingObject` gains `hitsRequired: Int` (1 or 2) and `hitsReceived: Int` (0 or 1)
- On first correct tap of armored object: decrement, stay on screen, emit `.objectDamaged` — no score/combo
- On second correct tap: remove, emit `.hit` — normal score, combo, explosion
- `LevelConfig` gains `armoredProbability: CGFloat` (0.0 tutorial → 0.25 hard)
- `SpawnScheduler` rolls probability per spawn to decide armored vs normal
- Ring drawn as rotating dashed stroke overlay in `FallingItemView`; hidden when `hitsReceived > 0`

## Architecture Notes

- Engine stays zero-UIKit; all animation in view layer
- `FallingObject` mutation on first hit is valid since it's a value type stored in `EngineState.fallingObjects` array — update in place via index
- Grace period logic unchanged: operates on symbol, not hit count
- Level-complete check unchanged: armored objects still count as falling until fully destroyed

## Edge Cases

- Armored object reaches ground: treated as miss (livesRemaining -= 1) regardless of hit count — no special handling
- Armored object with 1 hit remaining (ring gone) still counts as "on screen" for `maxOnScreen` guard
- Wrong tap with no armored target: existing `.noTarget` / grace period logic unchanged
- Retry: `engine.reset()` resets all `FallingObject` state — no stale hit counts

## Files Changed

| File | Change |
|------|--------|
| `Models/FallingObject.swift` | + `hitsRequired`, `hitsReceived` |
| `Models/DropRushGameState.swift` | + `GameEvent.objectDamaged`, update `TapResult` |
| `Engine/DropRushEngine.swift` | Update `handleTap` for 2-hit logic |
| `Engine/SpawnScheduler.swift` | Roll armored probability on spawn |
| `Models/LevelConfig.swift` | + `armoredProbability: CGFloat` |
| `Engine/LevelDefinitions.swift` | Set `armoredProbability` per tier |
| `Views/FallingItemView.swift` | Add glowing ring overlay + rotation animation |
| `ViewModels/DropRushGameViewModel.swift` | Handle `.objectDamaged` event (haptic/SFX) |
