---
title: "Rename currency to Gold and polish UI display"
description: "Rename all coin/currency identifiers to gold, migrate persistence key, polish Gold balance visibility across app"
status: complete
priority: P2
effort: 2h
branch: main
tags: [currency, rename, ui-polish]
created: 2026-03-13
completed: 2026-03-13
---

# Gold Currency Rename & UI Polish

## Objective

Rename the in-game currency from "coin/currency" to "Gold" throughout the codebase: types, properties, UI text, analytics events, persistence keys, comments. Polish Gold balance visibility in theme picker, settings, and win screens.

## Phase Overview

| Phase | Description | Status |
|-------|-------------|--------|
| 01 | Gold rename, persistence migration, UI polish, bug review | Complete |

## Key Decisions

- **Keep class name `GoldService`** (rename from `CurrencyService`) — aligns with new branding, small file so rename is clean
- **Keep analytics event strings as `gold_earned` / `gold_spent`** — new naming, no legacy analytics to preserve (app is pre-launch v1.0)
- **Persistence key migration**: read old key `app.currency.balance`, write to new `app.gold.balance`, delete old key on first load
- **File renames**: `CurrencyService.swift` -> `GoldService.swift`, `CoinBalanceView.swift` -> `GoldBalanceView.swift`, `CoinRewardToast.swift` -> `GoldRewardToast.swift`, `AnalyticsEvent+Currency.swift` -> `AnalyticsEvent+Gold.swift`

## Detailed Plan

See [phase-01-gold-rename-and-polish.md](./phase-01-gold-rename-and-polish.md)
