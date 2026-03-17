# Monetization V2 — Overview Plan

**Status:** Completed
**Priority:** High
**Target:** All games (Sudoku, DropRush, Stack2048)

## Context
- Existing: GoldService, StoreService (StoreKit2, removeAds + hintPack), AdsService (stub)
- Missing: Diamond currency, merge rewards, move streak, ad caps, daily login, piggy bank, advanced store, death popup redesign

## Phase Summary

| # | Phase | Status |
|---|-------|--------|
| 01 | [Diamond Service](./phase-01-diamond-service.md) | Completed |
| 02 | [Gold Economy Updates](./phase-02-gold-economy-updates.md) | Completed |
| 03 | [Rewarded Ads Flow](./phase-03-rewarded-ads-flow.md) | Completed |
| 04 | [Store + IAP Expansion](./phase-04-store-iap-expansion.md) | Completed |
| 05 | [UI Updates](./phase-05-ui-updates.md) | Completed |
| 06 | [High-Conversion Features](./phase-06-high-conversion-features.md) | Completed |
| 07 | [Analytics + Remote Config](./phase-07-analytics-remote-config.md) | Completed |

## Key Dependencies
1. Phase 01 (DiamondService) → must complete before 03, 04, 05, 06
2. Phase 02 (Gold updates) → independent, can run parallel to 01
3. Phase 03 (Ads flow) → needs 01 (diamonds) + 02 (gold caps)
4. Phase 04 (Store/IAP) → needs 01 (DiamondService)
5. Phase 05 (UI) → needs 01 + 02 + 04
6. Phase 06 (Conversion features) → needs all prior phases
7. Phase 07 (Analytics) → can start after 01–02, extends through all

## Economy Balance
- 1 small theme ≈ 1,000 gold ≈ 1 hour casual play
- 1 diamond ≈ 500–1,000 gold perceived value
- Merge reward: +10 gold for 2→4, doubles per tier (4→8=20, 8→16=40, …, 512→1024=160)
- Non-paying players must progress; purchases speed up / customize
