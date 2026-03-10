# SmartGames iOS — Sudoku v1 Implementation Plan

**Created:** 2026-03-10
**Status:** Complete
**Stack:** Swift 5.9+, SwiftUI, iOS 16+, Google AdMob, SwiftData

---

## Overview

iOS multi-game hub app. V1 ships **Sudoku only**. Architecture designed from day 1 to plug in additional mini-games (Parking Jam, Merge Puzzle, Block Puzzle, etc.) without structural changes.

Primary revenue: Google AdMob (rewarded + light interstitial). Priority v1: gameplay quality + retention over aggressive monetization.

---

## Phases

| # | Phase | Status | Priority | Effort |
|---|-------|--------|----------|--------|
| 01 | Project Setup & Architecture Scaffold | ✅ Done | Critical | S |
| 02 | Shared Services (Persistence, Settings, Sound, Analytics) | ✅ Done | Critical | M |
| 03 | Game Hub Screen | ✅ Done | High | S |
| 04 | Sudoku Engine (Puzzle Gen + Solver + Validation) | ✅ Done | Critical | L |
| 05 | Sudoku Gameplay UI | ✅ Done | Critical | L |
| 06 | Ads Integration (AdMob Rewarded + Interstitial) | ✅ Done | High | M |
| 07 | Analytics Events | ✅ Done | Medium | S |
| 08 | Polish, Testing & App Store Prep | ✅ Done | High | M |

---

## Phase Files

- [Phase 01 — Project Setup](./phase-01-project-setup.md)
- [Phase 02 — Shared Services](./phase-02-shared-services.md)
- [Phase 03 — Game Hub Screen](./phase-03-game-hub-screen.md)
- [Phase 04 — Sudoku Engine](./phase-04-sudoku-engine.md)
- [Phase 05 — Sudoku Gameplay UI](./phase-05-sudoku-gameplay-ui.md)
- [Phase 06 — Ads Integration](./phase-06-ads-integration.md)
- [Phase 07 — Analytics Events](./phase-07-analytics-events.md)
- [Phase 08 — Polish & Testing](./phase-08-polish-testing.md)

---

## Key Dependencies

```
Phase 01 → Phase 02 → Phase 03
                    → Phase 04 → Phase 05 → Phase 06 → Phase 07 → Phase 08
```

---

## PR Breakdown Summary

| PR | Phase | Goal |
|----|-------|------|
| PR-01 | 01 | Xcode project, folder structure, CI skeleton |
| PR-02 | 02 | Shared services: persistence, settings, sound, haptics |
| PR-03 | 03 | Game hub screen + navigation |
| PR-04 | 04 | Sudoku puzzle generator + solver + validator |
| PR-05 | 05a | Sudoku board UI + cell rendering + selection highlighting |
| PR-06 | 05b | Number input, undo, eraser, pencil mode, hint system |
| PR-07 | 05c | Game state machine (pause/resume, win, lose) + timer |
| PR-08 | 06 | AdMob rewarded + interstitial integration |
| PR-09 | 07 | Analytics events (Amplitude or Firebase) |
| PR-10 | 08 | Final polish, accessibility, App Store metadata |

---

## Research

- [Researcher 01 — iOS/SwiftUI/AdMob/Persistence](./research/researcher-01-report.md)

**Key research confirmations:**
- Backtracking + constraint propagation is correct for Sudoku generation ✓
- Google AdMob via SPM is the standard iOS integration ✓
- UserDefaults+JSON sufficient for v1 persistence (SwiftData optional upgrade for iOS 17+ in Phase 2) ✓
- ATT prompt should appear 2s after first launch, not on cold open ✓

---

## Assumptions

1. Target iOS 16+ (SwiftData requires iOS 17 — use UserDefaults+JSON fallback for iOS 16 support, or target iOS 17+ for simplicity).
2. Sudoku puzzles pre-generated at build time (large JSON bundle) + on-device generation as fallback.
3. Daily Challenge deferred to Phase 2.
4. Sound/haptics: basic only in v1 (tap, error, win).
5. No user accounts or leaderboards in v1.
6. AdMob test IDs used during dev; real IDs injected via CI env vars.
7. App name: "SmartGames" (subject to App Store availability check).
8. Mistake limit: 3 per game (as seen in reference screenshots).
