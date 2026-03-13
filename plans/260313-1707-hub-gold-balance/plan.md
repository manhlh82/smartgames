---
title: "Add Gold balance to Hub screen"
description: "Display GoldBalanceView in HubView toolbar so users see their balance on launch"
status: complete
priority: P2
effort: 15m
branch: main
tags: [ui, currency, hub]
created: 2026-03-13
---

# Hub Gold Balance Display

## Goal
Show Gold balance in HubView navigation bar (leading side) using existing `GoldBalanceView`.

## Phases

| # | Phase | Status | File |
|---|-------|--------|------|
| 1 | Add GoldBalanceView to HubView toolbar | Complete | [phase-01](phase-01-hub-gold-balance.md) |

## Scope
- **1 file changed**: `SmartGames/Hub/HubView.swift`
- **0 new files** — `GoldBalanceView` and `GoldService` already exist and are injected app-wide

## Dependencies
- `GoldBalanceView` (`SmartGames/Common/UI/GoldBalanceView.swift`)
- `GoldService` injected via `.environmentObject(environment.gold)` in `SmartGamesApp.swift`
