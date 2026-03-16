---
title: "Phase 1 — Engine: Hit-State Model, Tap Logic, Spawn Probability"
status: completed
priority: P0
effort: 2h
---

# Phase 1 — Engine & State Model

## Overview

Add armored-digit hit tracking to `FallingObject`, update `handleTap` to handle multi-hit logic, emit a new `objectDamaged` event on first hit, and configure per-level armored spawn probability.

## Related Files

- `SmartGames/Games/DropRush/Models/FallingObject.swift`
- `SmartGames/Games/DropRush/Models/DropRushGameState.swift`
- `SmartGames/Games/DropRush/Engine/DropRushEngine.swift`
- `SmartGames/Games/DropRush/Engine/SpawnScheduler.swift`
- `SmartGames/Games/DropRush/Models/LevelConfig.swift`
- `SmartGames/Games/DropRush/Engine/LevelDefinitions.swift`
- `SmartGames/Games/DropRush/ViewModels/DropRushGameViewModel.swift`

## Implementation Steps

### Step 1 — `FallingObject.swift`: Add hit-state fields

```swift
struct FallingObject: Identifiable, Equatable {
    let id: UUID
    let symbol: String
    var normalizedY: CGFloat
    let lane: Int
    let speed: CGFloat
    let hitsRequired: Int  // 1 = normal, 2 = armored
    var hitsReceived: Int  // 0 = untouched, 1 = first hit taken

    var isArmored: Bool { hitsRequired > 1 }
    var isVulnerable: Bool { hitsReceived >= hitsRequired - 1 }  // ready to destroy

    init(symbol: String, lane: Int, speed: CGFloat, hitsRequired: Int = 1) {
        self.id = UUID()
        self.symbol = symbol
        self.normalizedY = 0.0
        self.lane = lane
        self.speed = speed
        self.hitsRequired = hitsRequired
        self.hitsReceived = 0
    }
}
```

### Step 2 — `DropRushGameState.swift`: New event + updated TapResult

Add to `GameEvent`:
```swift
case objectDamaged(id: UUID, symbol: String)   // first hit on armored object — ring removed
```

Update `TapResult`:
```swift
enum TapResult {
    case hit(objectId: UUID, normalizedY: CGFloat, lane: Int, symbol: String)  // destroying hit
    case damaged(objectId: UUID)                                                 // first hit on armored
    case noTarget
}
```

### Step 3 — `DropRushEngine.swift`: Update `handleTap`

Replace the current "find target → remove → score" block:

```swift
func handleTap(symbol: String) -> TapResult {
    guard let idx = state.fallingObjects.indices
        .filter({ state.fallingObjects[$0].symbol == symbol })
        .max(by: { state.fallingObjects[$0].normalizedY < state.fallingObjects[$1].normalizedY })
    else {
        // no target — existing wrong-tap / grace-period logic unchanged
        state.wrongTaps += 1
        let justMissed = state.recentlyMissedSymbols[symbol].map { state.elapsedTime - $0 < 0.5 } ?? false
        if !justMissed {
            state.livesRemaining -= 1
            if state.livesRemaining <= 0 { state.isGameOver = true }
        }
        return .noTarget
    }

    let target = state.fallingObjects[idx]

    // First hit on armored object — decrement, stay on screen
    if !target.isVulnerable {
        state.fallingObjects[idx].hitsReceived += 1
        return .damaged(objectId: target.id)
    }

    // Destroying hit — remove from screen, award score + combo
    state.fallingObjects.remove(at: idx)
    state.comboCount += 1
    let newMultiplier: CGFloat
    switch state.comboCount {
    case ..<5:  newMultiplier = 1.0
    case ..<10: newMultiplier = 1.5
    case ..<15: newMultiplier = 2.0
    default:    newMultiplier = 2.5
    }
    state.comboMultiplier = newMultiplier
    state.score += scoreForHit(normalizedY: target.normalizedY)
    state.hits += 1
    return .hit(objectId: target.id, normalizedY: target.normalizedY, lane: target.lane, symbol: target.symbol)
}
```

**Edge cases handled:**
- `isVulnerable` true from the start for normal objects (hitsRequired == 1)
- First hit on armored: no combo, no score, no removal
- Armored object that reaches ground: miss logic runs on `normalizedY >= 1.0` regardless of hitsReceived
- Grace period: still keyed on `symbol`, unchanged

### Step 4 — `LevelConfig.swift`: Add `armoredProbability`

```swift
struct LevelConfig {
    // ... existing fields ...
    let armoredProbability: CGFloat  // 0.0 = no armored digits, 1.0 = all armored

    init(
        levelNumber: Int,
        symbolPool: [String],
        baseSpeed: CGFloat,
        spawnInterval: TimeInterval,
        maxOnScreen: Int,
        totalObjects: Int,
        speedPhases: [SpeedPhase] = SpeedPhase.standard,
        laneCount: Int? = nil,
        armoredProbability: CGFloat = 0.0   // default: no armored
    ) {
        // ...
        self.armoredProbability = armoredProbability
    }
}
```

### Step 5 — `SpawnScheduler.swift`: Roll armored probability on spawn

In `SpawnScheduler.makeObject(config:)` (or wherever `FallingObject` is constructed):

```swift
// Decide if this spawn should be armored
let isArmored = config.armoredProbability > 0 && CGFloat.random(in: 0..<1) < config.armoredProbability
let obj = FallingObject(
    symbol: symbol,
    lane: lane,
    speed: config.baseSpeed,
    hitsRequired: isArmored ? 2 : 1
)
```

### Step 6 — `LevelDefinitions.swift`: Set `armoredProbability` per tier

| Tier | Levels | armoredProbability |
|------|--------|--------------------|
| Tutorial | 1–5 | 0.0 |
| Easy | 6–15 | 0.0 |
| Medium | 16–30 | 0.10 |
| Hard | 31–40 | 0.20 |
| Expert | 41–50 | 0.30 |

Apply by adding `armoredProbability:` to the relevant `LevelConfig(...)` calls.

### Step 7 — `DropRushGameViewModel.swift`: Handle `.objectDamaged` event

In `handleTap(symbol:)`, add a case for the new `.damaged` result:

```swift
case .damaged:
    // First hit consumed — short medium impact + no explosion
    sound.playSFX("dropRush-hit")
    haptics.impact(.medium)   // slightly stronger than .light to signal "something happened"
```

In `handleEvent(_:)`, handle the new event (if we decide to emit it from the engine tick — likely not needed since it's already returned by `handleTap`). No changes required in `handleEvent` unless a future event is emitted.

## Todo

- [x] Add `hitsRequired` + `hitsReceived` + `isArmored` + `isVulnerable` to `FallingObject`
- [x] Add `GameEvent.objectDamaged` and `TapResult.damaged` to `DropRushGameState`
- [x] Update `handleTap` in engine with 2-hit branch
- [x] Add `armoredProbability` to `LevelConfig` with default 0.0
- [x] Update `SpawnScheduler` to roll armored probability
- [x] Tune `LevelDefinitions` with armoredProbability per tier
- [x] Handle `.damaged` TapResult in `DropRushGameViewModel.handleTap`
- [x] Compile & verify no regressions on normal 1-tap objects

## Success Criteria

- Normal objects (hitsRequired == 1): behaviour 100% unchanged
- Armored object: first tap leaves it on screen, second destroys it
- Wrong tap (no target) logic unchanged including grace period
- `hits` counter only increments on destroying tap
- Level complete triggers correctly when all armored objects are fully destroyed
- No crash when armored object reaches ground (standard miss flow)

## Risk Assessment

- `isVulnerable` short-circuits ensure normal objects take no extra code paths
- Mutating `FallingObject` in-place requires index-based access (not `filter` → `removeAll`) — avoid using the old `removeAll { $0.id == target.id }` pattern in engine, use `remove(at: idx)` instead
- `SpawnScheduler` may need refactoring if `FallingObject` construction is inline vs a factory method — check `SpawnScheduler.swift` to confirm pattern before implementing
