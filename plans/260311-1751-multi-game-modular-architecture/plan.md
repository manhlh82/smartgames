---
title: "Multi-Game Modular Architecture"
description: "Restructure SmartGames from monolithic single-game app to scalable multi-game platform"
status: completed
priority: P1
effort: 12h
branch: main
tags: [architecture, refactor, multi-game, modular]
created: 2026-03-11
completed: 2026-03-11
---

# Multi-Game Modular Architecture Plan

## Architecture Recommendation

**Folder-first modules** (no Swift packages in Phase 1). Current codebase already has
good separation (`Games/Sudoku/`, `SharedServices/`, `Common/`). Main work is:

1. Formalize `GameModule` protocol as plug-in contract
2. Decouple `AppRoute` and `ContentView` from Sudoku-specific types
3. Move Sudoku-specific services (`DailyChallengeService`, `StatisticsService`) into `Games/Sudoku/`
4. Create `FeatureGameHub` boundary with game registration via protocol

Swift packages can be adopted later (PR-16+) when there are 2+ games justifying build-time isolation.

## Module Structure

```
SmartGames/
  App/              (SmartGamesApp, AppEnvironment, ContentView)
  Core/             (GameModule protocol, AppRouter, AppRoute)
  FeatureGameHub/   (HubView, HubViewModel, GameCardView)
  Games/Sudoku/     (all Sudoku code, including Sudoku-specific services)
  SharedUI/         (AppColors, AppFonts, AppTheme, BoardTheme, PrimaryButton)
  SharedServices/   (Persistence, Settings, Sound, Haptics, Ads, Analytics, Store, GameCenter)
```

## Dependency Rules

SharedUI and SharedServices depend on nothing. Core depends on SharedUI/SharedServices.
Games/* depend on Core + SharedUI + SharedServices. FeatureGameHub depends on Core + SharedUI.
**No game module may import another game module.**

## Phases

| Phase | File | Status | Effort |
|-------|------|--------|--------|
| 1 | [phase-01-architecture-assessment.md](phase-01-architecture-assessment.md) | completed | 1h |
| 2 | [phase-02-module-design.md](phase-02-module-design.md) | completed | 2h |
| 3 | [phase-03-migration-plan.md](phase-03-migration-plan.md) | completed | 8h |
| 4 | [phase-04-ai-dev-guidelines.md](phase-04-ai-dev-guidelines.md) | completed | 1h |

## Completion Summary

All 18 implementation PRs (PR-11 through PR-18) successfully merged:

- **PR-11**: GameModule protocol + GameRegistry created
- **PR-12**: SudokuGameModule implemented, AppEnvironment updated
- **PR-13**: AppRoute refactored to generic gameLobby/gamePlay cases
- **PR-14**: Hub migrated to GameRegistry, folder structure reorganized
- **PR-15/17**: Skipped (cosmetic renames without functional impact)
- **PR-16**: Sudoku services moved to Games/Sudoku/, AppEnvironment simplified
- **PR-18**: EnvironmentObject injection cleaned up to minimal set

**Final State:**
- Folder-first modular architecture established (Swift packages deferred to Phase 2 expansion)
- Dependency rules enforced: Core imports SharedUI/SharedServices; Games/* depend on Core + SharedUI + SharedServices; no cross-game imports
- GameRegistry enables plug-and-play game registration without Hub/AppRoute modifications
- Codebase ready to add Game #2 with single-line registration in AppEnvironment
- Build: PASSED

**Next:** Begin Phase 2 expansion (new games, local Swift packages, cross-game features)
