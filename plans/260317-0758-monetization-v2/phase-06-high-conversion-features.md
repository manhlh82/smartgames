# Phase 06 — High-Conversion Features

**Priority:** Medium
**Status:** Completed
**Depends on:** Phases 01–05

## Overview
Implement the 10 high-conversion mechanics: Starter Bundle popup, piggy bank nudges, daily login streaks UI, time-limited sales, social share rewards, skip-ads pass trigger, and the "remove ads" soft banner.

## Related Code Files
- **Create:** `SmartGames/SharedComponents/StarterPackPopupView.swift` — first-session offer popup
- **Create:** `SmartGames/SharedComponents/TimedSalePopupView.swift` — after 2 losses in a row
- **Create:** `SmartGames/SharedComponents/DailyLoginPopupView.swift` — login streak reward popup
- **Create:** `SmartGames/SharedComponents/SocialShareView.swift` — share sheet + reward grant
- **Create:** `SmartGames/SharedComponents/SkipAdsBannerView.swift` — non-intrusive "Remove ads" banner
- **Modify:** `SmartGames/SharedServices/Store/StarterPackService.swift` — add loss-counter trigger
- **Create:** `SmartGames/SharedServices/Economy/SaleService.swift` — timed sale state + expiry
- **Modify:** `SmartGames/Games/DropRush/ViewModels/DropRushGameViewModel.swift` — track consecutive losses
- **Modify:** `SmartGames/Games/Stack2048/ViewModels/Stack2048GameViewModel.swift` — track consecutive losses
- **Modify:** `SmartGames/SharedServices/Economy/DailyLoginRewardService.swift` — add UI trigger published var

## 1 — Starter Bundle Popup
**Trigger:** First game loss OR `sessionElapsedTime >= 300s` (5 min), whichever comes first.
**Show once per install** (tracked by `StarterPackService.hasBeenOffered`).

`StarterPackPopupView`:
- Full-screen dimmed overlay, centered card
- Shows: exclusive theme thumbnail, "50 ◆ + Exclusive Theme"
- CTA: "Get Starter Pack – $X.XX" | "Maybe Later"
- On purchase: grant 50 diamonds + unlock exclusive theme, set `hasBeenClaimed = true`
- On dismiss: set `hasBeenOffered = true`, never show again

**Timer trigger:** In root `ContentView` or `AppViewModel`, start 5-min timer on first app open. Use `AppStorage` to mark first-open date.

## 2 — Time-Limited Sale (after 2 losses)
Track `consecutiveLosses: Int` in each game VM. Reset on win or new session.

`SaleService`:
- `activeSaleExpiry: Date?` (persist)
- `isSaleActive: Bool` — true if expiry is in future
- `triggerSale(duration: TimeInterval = 3600)` — sets expiry to now + 1h

`TimedSalePopupView`:
- Small bottom sheet (not full-screen)
- "⏰ 1h Sale — 100 diamonds for $X.XX (was $Y.YY)"
- Countdown timer label updates every second
- CTA: "Buy Now" | "×"
- Show after `consecutiveLosses == 2`; don't show again until next session

## 3 — Daily Login Streak UI
`DailyLoginPopupView`:
- 7-day calendar strip showing claimed (gold coin) vs upcoming days
- Day 7 highlighted with diamond icon
- Shows today's reward with bounce animation
- Auto-dismiss after 3s or on tap
- Triggered by `DailyLoginRewardService.pendingRewardToShow` published var

## 4 — Skip Ads CTA (after 2 ad-watches in session)
`SkipAdsBannerView`:
- Non-intrusive banner at bottom of screen (above game area)
- "Skip ads with ◆ 2 per session — or buy Skip Pass for $0.99"
- Two buttons: "Use Diamonds" | "Buy Pass"
- Triggered by `AdsService.sessionAdWatchCount == 2` notification
- Auto-hides after 8s

## 5 — "Remove Ads" Banner (after 3 ads/day)
- Same `SkipAdsBannerView` component, different text: "Remove all ads for $2.99"
- Triggered when `AdRewardTracker.adWatchCount >= 3`
- Links to `StoreService.removeAdsID` purchase

## 6 — Social Share Reward
`SocialShareView`:
- Wraps `UIActivityViewController` (share score screenshot)
- On successful share: grant `EconomyConfig.socialShareGold` (25 gold)
- Roll `EconomyConfig.socialShareDiamondChance` (0.001 = 0.1%) for 1 diamond
- Cap: 1 share reward per day (tracked in `AdRewardTracker` or separate key)
- Accessible from result overlays via share button

## 7 — Piggy Bank Nudge
- After 5 game sessions with no store visit: show small nudge notification in store icon badge
- When piggy bank reaches 80% full: show `GoldRewardToast`-style nudge: "Your piggy bank is almost full! 🐷"
- `PiggyBankService` publishes `nudgeFired: Bool` when threshold crossed

## Economy Constants to Add to EconomyConfig
```swift
// Conversion features
static let socialShareGold = 25
static let socialShareDiamondChance: Double = 0.001
static let timeLimitedSaleDuration: TimeInterval = 3600   // 1 hour
static let starterPackSessionTimerSeconds: Double = 300   // 5 min
static let consecutiveLossesForSale = 2
static let consecutiveLossesForStarterPack = 1
static let piggyBankNudgeThreshold: Double = 0.8          // 80% full
```

## Implementation Steps
1. Add `consecutiveLosses` tracker to DropRush + Stack2048 VMs; reset on win
2. Create `SaleService.swift` — active sale expiry, trigger method
3. Create `StarterPackPopupView.swift` — full overlay, purchase CTA
4. Create `TimedSalePopupView.swift` — bottom sheet, countdown timer
5. Create `DailyLoginPopupView.swift` — 7-day strip, animated reward
6. Create `SocialShareView.swift` — UIActivityViewController wrapper + reward grant
7. Create `SkipAdsBannerView.swift` — reusable for both "skip ads ◆" and "remove ads $2.99"
8. Wire starter pack trigger: 5-min timer in ContentView + loss trigger in game VMs
9. Wire timed sale trigger: `consecutiveLosses == 2` → `SaleService.triggerSale()`
10. Wire skip-ads banner: observe `AdsService.sessionAdWatchCount` changes
11. Wire "remove ads" banner: observe `AdRewardTracker.adWatchCount >= 3`
12. Add piggy bank nudge: `PiggyBankService` publishes nudge at 80% threshold
13. Inject `SaleService` into AppEnvironment

## Todo
- [ ] Add `consecutiveLosses` to DropRush + Stack2048 VMs
- [ ] Create `SaleService.swift`
- [ ] Create `StarterPackPopupView.swift`
- [ ] Create `TimedSalePopupView.swift` with live countdown
- [ ] Create `DailyLoginPopupView.swift`
- [ ] Create `SocialShareView.swift` + reward logic
- [ ] Create `SkipAdsBannerView.swift`
- [ ] Wire 5-min session timer for Starter Pack
- [ ] Wire timed sale trigger on 2 consecutive losses
- [ ] Wire skip-ads / remove-ads banner triggers
- [ ] Piggy bank nudge at 80% threshold
- [ ] Add social share economy constants
- [ ] Inject SaleService into AppEnvironment

## Success Criteria
- Starter Pack popup appears on first loss or after 5 min; never repeats after shown
- Timed sale shows after 2 consecutive losses with accurate 1h countdown
- Daily login popup shows correct streak day and reward amount
- Social share grants 25 gold; diamond reward logs to analytics
- Skip-ads banner appears after 2 session ad-watches; dismiss works
- Remove-ads banner appears after 3 daily ad-watches; links to correct IAP
- Piggy bank nudge fires at 80% fill
