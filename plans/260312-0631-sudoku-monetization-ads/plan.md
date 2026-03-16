---
title: "Sudoku Monetization & Ads"
description: "Full monetization spec: banner ads, post-level interstitial, rewarded hints (revised), rewarded mistake reset, per-game config model"
status: completed
priority: P1
effort: 18h
branch: main
tags: [monetization, ads, sudoku, banner, interstitial, rewarded]
created: 2026-03-12
---

# Sudoku Monetization & Ads

## Gap Analysis

### Already Covered

| Feature | Where | Notes |
|---------|-------|-------|
| Rewarded ad for hints (0 hints -> watch ad -> +3) | phase-06, SudokuGameViewModel L218-257 | Working. `grantHintsAfterAd()` adds 3, `applyHint()` uses 1 immediately |
| Rewarded ad for continue-after-lose | phase-06, SudokuGameViewModel L306-313 | `continueAfterAd()` resets mistakes to limit-1 |
| Interstitial post-win (max 1/session) | InterstitialAdCoordinator, AdsConfig | Rate-limited via `showCount` + cooldown |
| ATT prompt | phase-06 | 2s delay on first launch |
| Analytics: rewarded prompt/accept/decline/complete/fail | AnalyticsEvent+Ads.swift | 7 events implemented |
| Analytics: interstitial shown/dismissed | AnalyticsEvent+Ads.swift | 2 events |
| IAP Remove Ads + Hint Pack | phase-05-iap, StoreService | Gates both rewarded and interstitial via `storeService.hasRemovedAds` |
| Hint persistence (UserDefaults) | PersistenceService.Keys.sudokuHintsRemaining | Global across games |
| GameModule protocol | GameModule.swift | id, displayName, iconName, isAvailable, makeLobbyView, navigationDestination |

### Missing / Ambiguous

| Gap | Severity | Description |
|-----|----------|-------------|
| **No banner ad** | HIGH | PRD v1 explicitly excluded banners ("too disruptive"). New requirement adds persistent bottom banner. No `BannerAdCoordinator`, no `GADBannerView` wrapper, no ad unit ID for banner. |
| **No per-game monetization config** | HIGH | All ad params hardcoded in `AdsConfig` enum as static lets. No way to configure per-game. Adding a second game would require duplicating everything. |
| **Post-level interstitial every 1 level** | HIGH | Current: max 1 per session. New: every completed level. `InterstitialAdCoordinator.showCount` caps at 1. `maxInterstitialsPerSession=1`. Needs removal of session cap, add per-N-levels logic. |
| ~~Interstitial is 30s~~ | RESOLVED | Ad duration/skippability is SDK-controlled. Ignored from app perspective. |
| **Hint cap at 3** | HIGH | Current: `grantHintsAfterAd()` does `hintsRemaining += 3` with no cap. `grantHintsFromPurchase()` does `+= 10`. Hints can grow unbounded. Need `min(hintsRemaining + reward, maxHintCap)`. |
| **Level completion = +1 hint** | HIGH | Not implemented. `checkWin()` records stats but never grants hints. |
| **Rewarded mistake reset** | HIGH | Not implemented at all. No UI trigger, no ad flow, no analytics. `continueAfterAd()` only fires from lose screen (post-game-over), sets mistakes to limit-1, not 0. |
| **Banner analytics** | MEDIUM | No `ad_banner_*` events. Need impression, load_failed, click, refresh. |
| **Hint earned source tracking** | MEDIUM | No analytics differentiating hints earned from ad vs level vs IAP. |
| **Hint cap reached event** | LOW | No `hint_cap_reached` analytics event. |
| **Mistake reset analytics** | HIGH | No events for mistake reset flow. |
| **Ad unavailable event** | MEDIUM | `adRewardedFailed` exists but no generic `ad_unavailable` for UX fallback tracking. |
| **Drop-off near ad moments** | LOW | No specific event. Can be inferred from `game_abandoned` with `completion_pct`. |
| ~~Banner refresh interval configurable~~ | RESOLVED | SDK/AdMob dashboard controls refresh rate. Not app-configurable. Removed from MonetizationConfig. |
| **State persistence for mistake reset uses** | MEDIUM | Need to track per-level mistake reset count. Not in `SudokuGameState`. |
| **Per-game ad settings storage (future)** | LOW | Current: all static. Future: UserDefaults or remote config per game ID. |

## Implementation Phases

| # | Phase | File | Status | Effort |
|---|-------|------|--------|--------|
| 1 | Per-game Monetization Config Model | [phase-01](phase-01-monetization-config-model.md) | Completed | 2h |
| 2 | Banner Ad | [phase-02](phase-02-banner-ad.md) | Completed | 3h |
| 3 | Post-level Interstitial (revised) | [phase-03](phase-03-post-level-interstitial.md) | Completed | 2h |
| 4 | Rewarded Hints (revised) | [phase-04](phase-04-rewarded-hints.md) | Completed | 3h |
| 5 | Rewarded Mistake Reset | [phase-05](phase-05-rewarded-mistake-reset.md) | Completed | 3h |
| 6 | Analytics & UX Polish | [phase-06](phase-06-analytics-and-ux.md) | Completed | 5h |

**Dependencies:** Phase 1 -> Phase 2, 3, 4, 5 -> Phase 6

## PR Roadmap

| PR | Phase | Summary | Files Changed | Acceptance Criteria | Tests |
|----|-------|---------|---------------|---------------------|-------|
| PR-11 | 1 | Monetization config model | `MonetizationConfig.swift`, `AdsConfig.swift`, `GameModule.swift`, `SudokuModule.swift` | Config struct compiles; Sudoku module provides default config; `AdsConfig` reads from config | Unit: config defaults, config override |
| PR-12 | 2 | Banner ad | `BannerAdCoordinator.swift`, `BannerAdView.swift`, `AdsService.swift`, `SudokuGameView.swift`, `AdsConfig.swift` | Banner visible at bottom of game screen; respects safe area; auto-refreshes; hidden when `isAdsRemoved` | Manual: banner loads in simulator with test ID; layout doesn't break board |
| PR-13 | 3 | Post-level interstitial (revised) | `InterstitialAdCoordinator.swift`, `SudokuGameViewModel.swift`, `MonetizationConfig.swift` | Interstitial shows after every N completed levels (default 1); skippable after 5s; respects IAP | Unit: level counter increments; interstitial triggered at threshold |
| PR-14 | 4 | Rewarded hints (revised) | `SudokuGameViewModel.swift`, `MonetizationConfig.swift`, `SudokuGameView.swift` | +3 hints from ad (capped at 3); +1 hint on level complete (capped at 3); hints persist; display in toolbar | Unit: cap enforcement; level-complete grant; persistence |
| PR-15 | 5 | Rewarded mistake reset | `SudokuGameViewModel.swift`, `SudokuGameView.swift`, `AnalyticsEvent+Ads.swift` | Watch ad -> mistakes reset to 0; max 1 use per level; unavailable after game over; UI shows option | Unit: reset logic; usage limit; game-over guard |
| PR-16 | 6 | Analytics + UX | `AnalyticsEvent+Ads.swift`, `AnalyticsEvent+Sudoku.swift`, `SudokuGameView.swift`, `BannerAdCoordinator.swift` | All new events fire; ad-failure fallback UX; hint count always visible | Manual: verify events in Firebase DebugView |

## Key Architecture Decisions

1. **MonetizationConfig is a value type (struct)** -- injected via GameModule, not global singleton. Each game provides its own config.
2. **Banner uses `UIViewRepresentable`** wrapping `GADBannerView` -- standard pattern for AdMob in SwiftUI.
3. **Hint cap is enforced in a single place** -- `clampedHintGrant(_:)` helper in ViewModel, called by all grant paths (ad, level, IAP).
4. **Mistake reset is a new `GamePhase` case** (`needsMistakeResetAd`) -- mirrors existing `needsHintAd` pattern.
5. **Interstitial frequency uses a persistent level counter** per session, not total -- resets on app restart.
6. **Ad timing fully ignored** -- duration, refresh, and skippability are SDK-controlled. No app-side config needed or possible.
7. **IAP hint pack = 12 hints for $0.99** -- bypasses the 3-hint cap entirely. `grantHintsFromPurchase()` grants +12.
8. **Remove Ads = $4.99** -- already implemented in `SettingsView` ("Remove Ads" button → `PaywallView`). Already in `StoreService`. No new work required. PR-12 banner integration respects `storeService.hasRemovedAds` to skip banner.
9. **SettingsView label fix** -- "Get Hint Pack (10 Hints)" label in `SettingsView.swift:45` must be updated to "Get Hint Pack (12 Hints)" in PR-14.
