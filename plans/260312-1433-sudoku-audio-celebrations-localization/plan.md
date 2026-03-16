# Plan: Sudoku — Audio, Celebrations & Localization

**Date:** 2026-03-12
**Branch:** main
**Extends:** plans/260310-2040-ios-smartgames-sudoku/

## Gap Summary

| Area | Current State | Gap |
|------|---------------|-----|
| Background music | Not planned | Missing |
| Cell interaction sound | Tap sound exists, not wired to cell select | Under-specified |
| 3×3 subgrid celebration | Not planned | Missing |
| Full puzzle victory UI | Win screen exists; +1 hint & sound on win unclear | Under-specified |
| Localization | English-only, no .strings files | Missing |
| Settings: music toggle | No music property in SettingsService | Missing |
| Settings: language selector | Not in SettingsView or SettingsService | Missing |
| Analytics: audio/lang events | Not defined | Missing |
| Persistence: audio/lang prefs | Not persisted | Missing |

## What Is Already Covered

- `SoundService` exists with tap/error/win/hint SFX, settings-gated
- `SettingsService` has `isSoundEnabled` and `isHapticsEnabled` toggles
- `MonetizationConfig.levelCompleteHintReward = 1` is defined; `grantHints()` caps at `maxHintCap`
- `GameModule` protocol provides per-game extensibility hook
- Analytics infrastructure (AnalyticsService + AnalyticsEvent+Sudoku.swift) is in place
- `PersistenceService` supports any Codable key/value

## Phases

| Phase | Title | PR | Status |
|-------|-------|----|--------|
| 09 | Audio Infrastructure | PR-11 | Completed |
| 10 | Sudoku Completion Feedback (3×3 + Full) | PR-12 | Completed |
| 11 | Localization & Settings Language Support | PR-13 | Completed |

## Dependencies

- Phase 09 must complete before Phase 10 (SFX hooks required)
- Phase 11 is independent and can be built in parallel with 09+10
