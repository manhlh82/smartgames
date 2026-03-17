# Phase 03 — Rewarded Ads Flow

**Priority:** High
**Status:** Completed
**Depends on:** Phase 01 (DiamondService), Phase 02 (AdRewardTracker)

## Overview
Overhaul rewarded ad outcomes: tiered rewards (gold, continue, undo, rare diamond), daily cap enforcement, and conversion nudges (skip-ads CTA after 2 watches, Starter Pack after 2 watches or first loss).

## Related Code Files
- **Modify:** `SmartGames/SharedServices/Ads/RewardedAdCoordinator.swift` — add reward type enum + outcome dispatch
- **Modify:** `SmartGames/SharedServices/Ads/AdsService.swift` — expose session ad-watch count
- **Modify:** `SmartGames/Games/DropRush/ViewModels/DropRushGameViewModel+Actions.swift` — wire diamond continue option
- **Modify:** `SmartGames/Games/Stack2048/ViewModels/Stack2048GameViewModel.swift` — wire diamond continue + undo
- **Modify:** `SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift` — wire diamond undo
- **Create:** `SmartGames/SharedServices/Ads/RewardedAdOutcome.swift` — reward type definitions
- **Modify:** `SmartGames/SharedServices/Analytics/AnalyticsEvent+Ads.swift` — add reward outcome events

## Reward Type Enum
```swift
enum RewardedAdOutcome {
    case gold(Int)          // 50 gold — common
    case continueHeart(Int) // restore N hearts — common
    case undo               // 1 free undo — rare (shown only in-game)
    case diamond(Int)       // 1 diamond — very rare (0.2% roll)
}
```

## Ad Reward Logic (in RewardedAdCoordinator)
```swift
func resolveOutcome(context: AdContext) -> RewardedAdOutcome {
    // 0.2% diamond chance first
    if Double.random(in: 0..<1) < EconomyConfig.adDiamondChance {
        return .diamond(1)
    }
    switch context {
    case .goldReward:   return .gold(EconomyConfig.adWatchGold)   // 50
    case .continue:     return .continueHeart(3)
    case .undo:         return .undo
    }
}
```

## Session Ad-Watch Counter
- `AdsService` tracks `sessionAdWatchCount: Int` (in-memory, resets on app cold start)
- After `sessionAdWatchCount == 2`: post `NotificationCenter` event `.showSkipAdsCTA`
- After `sessionAdWatchCount == 2` OR on first game loss: post `.showStarterPackOffer`
- Both notifications observed by relevant view models / root view

## Daily Cap Enforcement
- Before showing rewarded ad for gold: check `AdRewardTracker.canWatchAd()`
- If cap reached: show "Come back tomorrow" message instead of ad
- Cap applies only to gold-reward ads; continue/undo ads bypass cap (UX: don't punish stuck players)

## Continue via Diamond
- Death popup (Phase 05) offers: Left = Watch Ad (restore 1 heart) | Right = 2 Diamonds (full restore)
- If player taps Diamond continue:
  - `diamondService.spend(amount: DiamondReward.continueFullRevive)` → if true, restore all hearts
  - Else: show "Not enough diamonds" with store link

## Undo via Diamond
- Undo button shows sub-option sheet: "Watch Ad" | "Use 1 Diamond" | "Cancel"
- Diamond undo: `diamondService.spend(amount: DiamondReward.undoCost)` → perform undo if success
- Ad undo: show rewarded ad → on completion perform undo

## Implementation Steps
1. Create `RewardedAdOutcome.swift` with enum + `AdContext` enum
2. Update `RewardedAdCoordinator` — add `resolveOutcome(context:)`, dispatch reward to GoldService/DiamondService
3. Add `sessionAdWatchCount` to `AdsService`; post notifications at thresholds
4. Update `MonetizationConfig` — add `adDiamondChance: Double = 0.002`
5. Enforce daily cap in gold-reward ad path; bypass for continue/undo
6. Update DropRush result overlay — pass diamond-continue action
7. Update Stack2048 game over overlay — pass diamond-continue action
8. Update Sudoku undo logic — show watch-ad / use-diamond sheet
9. Add analytics: `adRewardGranted(outcome:context:)`, `adCapReached()`, `skipAdsCTAShown()`, `starterPackOfferShown(trigger:)`

## Todo
- [ ] Create `RewardedAdOutcome.swift`
- [ ] Update `RewardedAdCoordinator` with outcome resolution
- [ ] Add `sessionAdWatchCount` + notification posts to `AdsService`
- [ ] Enforce daily cap (gold ads only)
- [ ] Wire diamond-continue into DropRush death overlay
- [ ] Wire diamond-continue into Stack2048 game over overlay
- [ ] Wire diamond/ad undo into Sudoku undo button
- [ ] Add analytics events for all ad outcomes
- [ ] Add `adDiamondChance` to `MonetizationConfig` / `EconomyConfig`

## Success Criteria
- Rewarded ad grants 50 gold (common), 1 heart (continue), or 1 diamond (0.2% verified via analytics)
- Daily gold-ad cap enforced at 5; continue/undo ads not capped
- After 2 session ad-watches: skip-ads CTA visible
- Diamond continue: 2 diamonds spent, full hearts restored
- Diamond undo: 1 diamond spent, last move reverted
