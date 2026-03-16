---
title: "Themes & In-Game Currency System"
description: "Add 9 app themes (2 free, 7 paid) with shared in-game currency earned from gameplay"
status: completed
priority: P2
effort: 6h
branch: kai/feat/themes-and-currency
tags: [themes, currency, monetization, ui]
created: 2026-03-13
---

# Themes & In-Game Currency

## Summary

Add 9 board themes (2 free, 7 purchasable) and a shared in-game currency system. Players earn coins by completing levels in any game (Sudoku, Drop Rush). Coins buy premium themes permanently.

## Architecture Decisions

1. **CurrencyService** -- new `@MainActor ObservableObject` in `SharedServices/Currency/`. Separate from SettingsService (different concern, different persistence keys). Injected via `AppEnvironment`.
2. **ThemeService** -- already exists at `SharedServices/Theme/ThemeService.swift`. Extend it with unlock logic (keeps theme concern cohesive). Add `unlockedThemes: Set<BoardThemeName>` property.
3. **Theme application** -- keep current `@EnvironmentObject var themeService: ThemeService` pattern. No app-wide color scheme override needed (themes are board-level, not system-level).
4. **Currency rewards** -- ViewModels call `currencyService.earn(amount:reason:)` at level-complete. No duplicate-reward guard needed because reward is per-completion event, not per-level-ID.

## Phases

| Phase | PR | Status | Effort |
|-------|-----|--------|--------|
| [Phase 1: Currency Model & Rewards](phase-01-currency-model-and-rewards.md) | PR1 | completed | 2h |
| [Phase 2: Theme Catalog & Unlock](phase-02-theme-catalog-and-unlock.md) | PR2 | completed | 2h |
| [Phase 3: UI Theme Picker & Polish](phase-03-ui-theme-picker-and-polish.md) | PR3 | completed | 2h |

## Dependencies

- Phase 2 depends on Phase 1 (unlock requires currency check)
- Phase 3 depends on Phase 2 (picker needs unlock state + purchase flow)

## Currency Economy

| Source | Amount |
|--------|--------|
| Sudoku puzzle complete | 15 coins |
| Sudoku 3-star bonus | +10 coins |
| Drop Rush level complete | 10 coins |
| Drop Rush 3-star bonus | +10 coins |

| Theme | Price |
|-------|-------|
| Dark, Light (Classic) | FREE |
| Cherry | 50 coins |
| Brownish Calm | 50 coins |
| High Contrast | 50 coins |
| Yellow-ish White Paper | 50 coins |
| Nature | 75 coins |
| Cityscapes | 75 coins |
| Snowy | 100 coins |
