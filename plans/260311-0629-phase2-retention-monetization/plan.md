---
title: "Phase 2: Retention & Monetization"
description: "Add dark mode, stats, daily challenge, Game Center, and IAP to SmartGames Sudoku"
status: Complete
priority: P1
effort: 28h
branch: feat/phase2-retention-monetization
tags: [ios, sudoku, monetization, retention, phase2]
created: 2026-03-11
completed: 2026-03-11
---

# Phase 2: Retention & Monetization

## Summary

Phase 2 adds retention (daily challenge, stats, Game Center) and monetization (IAP) features to the SmartGames Sudoku app. Ordered by shipping speed: local-only features first, Apple API integrations last.

## Architecture Principles

- Extend existing `AppEnvironment` DI container for new services
- Use existing `PersistenceService` (UserDefaults+JSON) for all local storage
- Extend existing `SettingsService` for theme/preference additions
- New services: `ThemeService`, `StatisticsService`, `DailyChallengeService`, `GameCenterService`, `StoreService`
- All new routes added to `AppRoute` enum, views registered in `ContentView`

## Phase Overview

| # | Phase | Effort | Status | Dependencies |
|---|-------|--------|--------|-------------|
| 1 | [Dark Mode + Board Themes](phase-01-dark-mode-themes.md) | 4h | ✅ Done | None |
| 2 | [Statistics Screen](phase-02-statistics-screen.md) | 4h | ✅ Done | None |
| 3 | [Daily Challenge](phase-03-daily-challenge.md) | 8h | ✅ Done | Phase 2 (stats integration) |
| 4 | [Game Center](phase-04-game-center.md) | 5h | ✅ Done | Phase 2 (scores to submit) |
| 5 | [IAP: Remove Ads + Hint Packs](phase-05-iap.md) | 7h | ✅ Done | Phase 1 (theme gating optional) |

## Key Decisions

1. **Daily Challenge uses deterministic seeding** (date-based seed to `SudokuGenerator`) -- no server needed for MVP
2. **StoreKit 2** async/await API (iOS 15+, our min is 16+, so safe)
3. **Theme system** uses `@EnvironmentObject ThemeService` providing computed `BoardTheme` palettes
4. **Stats are per-difficulty** -- existing `SudokuStats` struct extended with `totalTimeSeconds`, `currentStreak`, `bestStreak`
5. **Game Center** scores = best time per difficulty (lower is better)

## Shared Infrastructure Changes

Files modified across multiple phases:
- `AppEnvironment.swift` -- add new services
- `AppRoute.swift` -- add `.statistics`, `.dailyChallenge` routes
- `PersistenceService.swift` -- add new keys
- `SettingsService.swift` -- add theme preference
- `SmartGamesApp.swift` -- inject new environment objects
- `SudokuLobbyView.swift` -- add stats/daily challenge entry points
- `SudokuGameViewModel.swift` -- integrate stats recording, Game Center score submission
- `SudokuWinView.swift` -- add "Share" and leaderboard link

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| StoreKit 2 sandbox flaky in simulator | Medium | Test on device; use `StoreKit Configuration` file |
| Game Center auth interrupts gameplay | Low | Auth on app launch, not mid-game |
| Daily Challenge timezone edge cases | Medium | Use UTC calendar consistently |
| Theme colors accessibility contrast | Medium | Test with Accessibility Inspector; maintain WCAG AA |
