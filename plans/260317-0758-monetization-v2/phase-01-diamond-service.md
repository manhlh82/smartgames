# Phase 01 — Diamond Service

**Priority:** Critical (blocks phases 03–06)
**Status:** Completed

## Overview
Introduce a Diamond (premium) currency mirroring GoldService. Diamonds are earned rarely (free drops, events) and spent on continues, undos, premium cosmetics. All IAP diamond grants flow through DiamondService.

## Related Code Files
- **Modify:** `SmartGames/SharedServices/Gold/GoldService.swift` — add `DiamondReward` enum alongside `GoldReward`
- **Create:** `SmartGames/SharedServices/Diamond/DiamondService.swift`
- **Modify:** `SmartGames/SharedServices/AppEnvironment.swift` — inject DiamondService
- **Modify:** `SmartGames/SharedServices/Persistence/PersistenceService.swift` — add `diamondBalance` key
- **Create:** `SmartGames/SharedServices/Analytics/AnalyticsEvent+Diamond.swift`

## Diamond Reward Constants
```swift
enum DiamondReward {
    // Free drops
    static let bigMergeDropChance: Double = 0.005  // 0.5% on merge ≥256
    static let adWatchDropChance: Double = 0.002   // 0.2% per rewarded ad
    // Event
    static let weeklyChallengMin = 1
    static let weeklyChallengMax = 3
    // Spend
    static let continueFullRevive = 2
    static let undoCost = 1
}
```

## Implementation Steps
1. Add `PersistenceService.Keys.diamondBalance = "app.diamond.balance"` key
2. Create `DiamondService.swift` — identical structure to GoldService:
   - `@Published private(set) var balance: Int`
   - `earn(amount:)` — overflow-safe, capped at Int.max / 2
   - `spend(amount:) -> Bool` — returns false if insufficient
   - Persist on every mutation
3. Add `DiamondReward` enum to `GoldService.swift` (same file or new `CurrencyRewards.swift`)
4. Inject `DiamondService` into `AppEnvironment` alongside `GoldService`
5. Create `AnalyticsEvent+Diamond.swift`:
   - `diamondEarned(amount:source:balanceAfter:)`
   - `diamondSpent(amount:reason:balanceAfter:)`
   - `diamondDropRolled(tileValue:didDrop:)` — for A/B tuning drop rate
6. Wire drop logic into merge event handlers (Stack2048, DropRush) — roll `Double.random(in: 0..<1) < DiamondReward.bigMergeDropChance` when merged tile ≥ 256

## Todo
- [ ] Add `diamondBalance` persistence key
- [ ] Create `DiamondService.swift`
- [ ] Create `DiamondReward` constants
- [ ] Inject into AppEnvironment
- [ ] Create analytics events
- [ ] Wire big-merge drop into Stack2048GameViewModel
- [ ] Wire big-merge drop into DropRushGameViewModel (if merge ≥256 is possible)
- [ ] Unit test: earn, spend, overflow, insufficient balance

## Success Criteria
- Diamond balance persists across app restarts
- Big-merge drop fires at ~0.5% rate (verified by analytics `diamondDropRolled`)
- All other phases can access DiamondService via @EnvironmentObject

## Notes
- Do NOT add diamond UI yet — that is Phase 05
- Drop roll must happen inside @MainActor game VM, not in service
