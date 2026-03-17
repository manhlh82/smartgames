---
title: "Crossword Game Module"
description: "Add crossword puzzle game to SmartGames with grid input, hints, daily challenges, and monetization"
status: pending
priority: P1
effort: 12h
branch: main
tags: [crossword, new-game, feature]
created: 2026-03-17
---

# Crossword Game Module

## Overview

New Crossword game module following existing GameModule protocol. Supports Mini (5x5) and Standard (9x9) grids with hand-coded JSON puzzles, hint system (check/reveal letter/reveal word), free undo, daily challenges, and full monetization integration.

## Phases

| # | Phase | Files | Status |
|---|-------|-------|--------|
| 1 | [Models + Engine](phase-01-models-and-engine.md) | 6 new | pending |
| 2 | [ViewModel](phase-02-viewmodel.md) | 1 new | pending |
| 3 | [Core Views](phase-03-core-views.md) | 4 new | pending |
| 4 | [Lobby + Win + Pause](phase-04-lobby-win-pause.md) | 4 new | pending |
| 5 | [Daily Challenge](phase-05-daily-challenge.md) | 3 new | pending |
| 6 | [Module + Integration](phase-06-module-integration.md) | 4 modified, 1 new | pending |
| 7 | [Polish + Testing](phase-07-polish-testing.md) | 0 new | pending |

## Dependencies

- Phases 1→2→3→4 (sequential: models feed VM feed views)
- Phase 5 depends on Phase 2 (VM patterns)
- Phase 6 depends on Phases 4+5 (all files exist)
- Phase 7 depends on Phase 6 (full integration)

## Key Decisions

- ~20 hand-coded JSON puzzles (no generator needed)
- Undo is FREE (max depth 20)
- Pencil mode deferred to V2 (YAGNI)
- Reuse `DiamondReward.undoCost = 1` for reveal-letter cost
- No mistake limit (crosswords don't traditionally have one)
- MonetizationConfig: banner=true, interstitial=true, freq=2, rewardedHints=true, amount=3, levelCompleteReward=1, maxCap=5, mistakeReset=false

## File Map

```
SmartGames/Games/Crossword/
├── CrosswordModule.swift                          (Phase 6)
├── Engine/
│   ├── CrosswordPuzzleBank.swift                  (Phase 1)
│   └── CrosswordValidator.swift                   (Phase 1)
├── Models/
│   ├── CrosswordPuzzle.swift                      (Phase 1)
│   ├── CrosswordBoardState.swift                  (Phase 1)
│   ├── CrosswordGameState.swift                   (Phase 1)
│   └── CrosswordDailyChallengeModels.swift         (Phase 5)
├── ViewModels/
│   └── CrosswordGameViewModel.swift               (Phase 2)
├── Views/
│   ├── CrosswordGameView.swift                    (Phase 3)
│   ├── CrosswordGridView.swift                    (Phase 3)
│   ├── CrosswordCellView.swift                    (Phase 3)
│   ├── CrosswordClueBarView.swift                 (Phase 3)
│   ├── CrosswordClueListView.swift                (Phase 4)
│   ├── CrosswordToolbarView.swift                 (Phase 3)
│   ├── CrosswordLobbyView.swift                   (Phase 4)
│   ├── CrosswordWinView.swift                     (Phase 4)
│   └── CrosswordPauseOverlay.swift                (Phase 4)
├── Services/
│   └── CrosswordDailyChallengeService.swift       (Phase 5)
└── Resources/
    └── crossword-puzzles.json                     (Phase 1)
```

Modified files: `AppEnvironment.swift`, `SmartGamesApp.swift`, `project.yml`, `AnalyticsEvent+Crossword.swift` (new shared file)
