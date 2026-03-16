---
title: "Phase 2 — Visual: Glowing Animated Ring + First-Hit Transition"
status: completed
priority: P0
effort: 2h
---

# Phase 2 — Visual: Glowing Animated Ring

## Overview

`FallingItemView` gains a rotating dashed ring overlay when `object.isArmored && object.hitsReceived == 0`.
After the first correct tap, `hitsReceived` becomes 1 — SwiftUI transitions the ring out, leaving a plain falling digit that signals "one more tap".

## Related Files

- `SmartGames/Games/DropRush/Views/FallingItemView.swift`

## Design Spec

| State | Visual |
|-------|--------|
| `hitsRequired == 1` (normal) | No ring — unchanged |
| `hitsRequired == 2`, `hitsReceived == 0` (armored, untouched) | Glowing ring, rotating, pulsing opacity |
| `hitsRequired == 2`, `hitsReceived == 1` (armored, hit once) | Ring gone; digit fades briefly then continues |
| Danger zone (`normalizedY > 0.85`) | Red pulsing border — unchanged, layered under ring |

**Ring spec:**
- Dashed `Circle` stroke, lineWidth 3, dash pattern `[8, 4]`
- Color: white at 0.9 opacity (works on all symbol colors)
- Outer glow shadow: same color, blur radius 6
- Rotation: continuous `360°` over `2.0s`, `.linear`, `.repeatForever(autoreverses: false)`
- Opacity pulse: `0.6 → 1.0` over `0.8s`, `.easeInOut`, `.repeatForever(autoreverses: true)`
- Ring diameter: symbol circle + 10pt padding (i.e. frame 58×58 over 48×48 circle)
- Transition out: `.scale(0.4).combined(with: .opacity)`, duration `0.2s`

## Implementation Steps

### Step 1 — Add `@State` animation drivers

```swift
struct FallingItemView: View {
    let object: FallingObject
    let areaHeight: CGFloat
    let laneWidth: CGFloat

    @State private var ringRotation: Double = 0
    @State private var ringOpacity: Double = 0.6
    // ...
}
```

### Step 2 — Computed helpers

```swift
private var isDanger: Bool { object.normalizedY > 0.85 }
private var showArmorRing: Bool { object.hitsRequired > 1 && object.hitsReceived == 0 }
```

### Step 3 — Build ring overlay

Extract the ring into a private computed view for readability:

```swift
private var armorRing: some View {
    Circle()
        .strokeBorder(
            style: StrokeStyle(lineWidth: 3, dash: [8, 4])
        )
        .foregroundStyle(.white.opacity(ringOpacity))
        .frame(width: 58, height: 58)
        .shadow(color: .white.opacity(0.8), radius: 6)
        .rotationEffect(.degrees(ringRotation))
}
```

### Step 4 — Apply overlay with conditional transition

```swift
var body: some View {
    ZStack {
        Text(object.symbol)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .frame(width: 48, height: 48)
            .foregroundStyle(.white)
            .background(DropRushColors.color(for: object.symbol))
            .clipShape(Circle())
            .shadow(color: DropRushColors.color(for: object.symbol).opacity(0.4), radius: 6, y: 3)
            .overlay(
                Circle()
                    .stroke(Color.red.opacity(isDanger ? 0.85 : 0), lineWidth: 3)
                    .animation(
                        isDanger
                            ? .easeInOut(duration: 0.3).repeatForever(autoreverses: true)
                            : .default,
                        value: isDanger
                    )
            )

        if showArmorRing {
            armorRing
                .transition(
                    .scale(scale: 0.4)
                    .combined(with: .opacity)
                )
        }
    }
    .animation(.easeOut(duration: 0.2), value: showArmorRing)
    .onAppear {
        guard showArmorRing else { return }
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            ringOpacity = 1.0
        }
    }
    .position(
        x: CGFloat(object.lane) * laneWidth + laneWidth / 2,
        y: object.normalizedY * areaHeight
    )
}
```

**Why `ZStack` instead of `.overlay`?**
The ring is 58×58 and the digit is 48×48. Using `.overlay` would clip the ring. `ZStack` lets both live at natural size, and `.position` is applied to the whole `ZStack` so layout is unchanged.

### Step 5 — Edge case: ring starts only on `onAppear`

When `hitsReceived` flips from 0→1, `showArmorRing` becomes `false` and the `if` block removes the `armorRing` view from the hierarchy. The `.animation(.easeOut(duration: 0.2), value: showArmorRing)` on the `ZStack` drives the transition. The `@State` rotation/opacity values are naturally reset next time this view appears (a new armored object).

**No `onChange(of:)` needed** — SwiftUI structural identity handles the ring view lifecycle.

## Todo

- [x] Add `@State private var ringRotation` and `ringOpacity` to `FallingItemView`
- [x] Add `showArmorRing` computed var
- [x] Extract `armorRing` private computed view
- [x] Wrap existing content in `ZStack`, apply `if showArmorRing` block with transition
- [x] Add `.animation` on ZStack for ring removal
- [x] Start ring animations in `onAppear` guarded by `showArmorRing`
- [x] Move `.position(...)` to the `ZStack` level
- [x] Visual test: spawn an armored object, tap once, verify ring disappears cleanly
- [x] Visual test: danger zone red ring and armor ring coexist correctly

## Success Criteria

- Armored digit has clearly visible rotating dashed ring from the moment it spawns
- Ring disappears smoothly (scale + fade) immediately after first correct tap
- Normal digits (hitsRequired == 1): no ring, no behaviour change
- Danger zone red pulse still visible underneath/alongside armor ring
- No layout shift when ring appears/disappears
- Animation does not stutter when scrolling or during speed phase changes

## Risk Assessment

- `@State` animation drivers inside a list/ForEach-rendered view reset on identity change — this is fine here because each `FallingObject` has a stable `UUID` identity; SwiftUI won't recreate the view unless the object is removed
- `onAppear` fires once per view instantiation; ring animations start correctly for newly spawned armored objects
- If an armored object is spawned but immediately enters danger zone, both the armor ring and danger ring should coexist — verify visually that opacity/z-order is acceptable
