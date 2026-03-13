---
phase: 1
title: "Add GoldBalanceView to HubView toolbar"
status: complete
priority: P2
effort: 15m
---

# Phase 1 — Hub Gold Balance

## Context
- [HubView.swift](../../SmartGames/Hub/HubView.swift) — target file
- [GoldBalanceView.swift](../../SmartGames/Common/UI/GoldBalanceView.swift) — reusable component
- `GoldService` already injected app-wide in `SmartGamesApp.swift`

## Overview
Add a leading `ToolbarItem` containing `GoldBalanceView()` to HubView's existing `.toolbar` block.

## Related Code Files
- **Modify**: `SmartGames/Hub/HubView.swift`

## Implementation Steps

1. Open `SmartGames/Hub/HubView.swift`
2. Inside the existing `.toolbar { ... }` block (line 31), add a new `ToolbarItem` **before** the trailing settings button:
   ```swift
   ToolbarItem(placement: .navigationBarLeading) {
       GoldBalanceView()
   }
   ```
3. Build project — confirm no compile errors
4. Run on simulator — verify Gold badge appears left of nav title, settings gear stays on right

## Todo List
- [x] Add leading `ToolbarItem` with `GoldBalanceView()` in HubView toolbar
- [x] Verify compile succeeds
- [x] Visual check: balance visible on hub, updates when Gold changes

## Success Criteria
- Gold balance badge visible in HubView navigation bar (leading position)
- No new files created
- Existing tests still pass
- `GoldBalanceView` reads from injected `GoldService` — no additional wiring needed

## Risk Assessment
- **Low**: `GoldBalanceView` may look cramped with large title mode — if so, switch to `.navigationBarTitleDisplayMode(.inline)` or adjust font. Verify visually first.
