# Phase 02 — Gold Economy Updates

**Priority:** High
**Status:** Completed

## Overview
Update gold earning to match new economy spec: per-merge rewards (scale by tile value), move-streak bonuses, per-day ad watch cap, and daily login rewards. All values consolidated in a remote-config-ready economy struct.

## Related Code Files
- **Modify:** `SmartGames/SharedServices/Gold/GoldService.swift` — update `GoldReward` constants
- **Create:** `SmartGames/SharedServices/Economy/EconomyConfig.swift` — all economy constants in one place
- **Modify:** `SmartGames/Games/Stack2048/ViewModels/Stack2048GameViewModel+GameEvents.swift` — add per-merge gold
- **Modify:** `SmartGames/Games/DropRush/ViewModels/DropRushGameViewModel.swift` — add per-merge gold + move streak
- **Create:** `SmartGames/SharedServices/Economy/AdRewardTracker.swift` — daily ad-watch cap
- **Create:** `SmartGames/SharedServices/Economy/DailyLoginRewardService.swift` — login streak + reward
- **Modify:** `SmartGames/SharedServices/Persistence/PersistenceService.swift` — add keys for streak data, last login date, daily ad count

## Economy Config (new file)
```swift
struct EconomyConfig {
    // Gold — merge rewards
    static let mergeBaseGold = 10        // gold for 2→4 merge
    // Reward = mergeBaseGold * 2^(log2(resultTile) - 2)
    // 2→4: 10, 4→8: 20, 8→16: 40, 16→32: 80, …, 256→512: 1280 — cap at 512
    static let mergeGoldCap = 512

    // Gold — move streak
    static let moveStreakInterval = 5    // every N valid moves
    static let moveStreakBonus = 5

    // Gold — ad watch
    static let adWatchGold = 50
    static let adWatchDailyMax = 5       // cap per calendar day

    // Gold — daily login (index 0 = day 1)
    static let dailyLoginRewards = [100, 150, 200, 250, 300, 350, 400]
    // Loops at index 6 (day 7+)

    // Diamond — daily login day 7
    static let dailyLoginDiamondDay = 7
    static let dailyLoginDiamondAmount = 1
}
```

## Merge Gold Formula
For a resulting tile value `v` (e.g. 8 from merging two 4s):
```swift
func mergeGold(resultTileValue: Int) -> Int {
    guard resultTileValue >= 4 else { return 0 }
    let exponent = Int(log2(Double(resultTileValue))) - 2  // 4→0, 8→1, 16→2
    let reward = EconomyConfig.mergeBaseGold * (1 << exponent)
    return min(reward, EconomyConfig.mergeGoldCap)
}
```

## Implementation Steps

### 2a — EconomyConfig
1. Create `SmartGames/SharedServices/Economy/EconomyConfig.swift` with all constants above
2. Remove inline `GoldReward` constants from `GoldService.swift` — replace references with `EconomyConfig`

### 2b — Per-Merge Gold (Stack2048)
1. In `Stack2048GameViewModel+GameEvents.swift`, hook into merge callback
2. On each merge event: compute `mergeGold(resultTileValue:)`, call `goldService.earn(amount:)`
3. Accumulate `goldEarnedThisSession` for display; fire `analyticsEvent.goldEarned`

### 2c — Per-Merge Gold (DropRush)
1. Same pattern in `DropRushGameViewModel` — hook tile-merge callback
2. Compute + grant gold per merge

### 2d — Move Streak Bonus
1. Add `moveCount: Int` tracker in each game VM
2. On each valid move: `moveCount += 1`; if `moveCount % EconomyConfig.moveStreakInterval == 0`, earn `EconomyConfig.moveStreakBonus` gold
3. Reset `moveCount` on game over / new game

### 2e — Ad Watch Daily Cap (AdRewardTracker)
Create `AdRewardTracker.swift`:
- Persist `adWatchDate: Date` and `adWatchCount: Int`
- `func canWatchAd() -> Bool` — resets count if calendar day changed
- `func recordAdWatch()` — increments count, saves
- Used in Phase 03 rewarded ad flow before granting gold

### 2f — Daily Login Reward Service
Create `DailyLoginRewardService.swift`:
- Persist `lastLoginDate: Date`, `loginStreakCount: Int`
- On app foreground: check if calendar day differs from `lastLoginDate`
- If new day: increment streak, grant `EconomyConfig.dailyLoginRewards[min(streak-1, 6)]` gold
- If streak day == 7: also grant 1 diamond via DiamondService
- Emit `GoldRewardToast` trigger via published property
- Reset streak if gap > 1 day

## Todo
- [ ] Create `EconomyConfig.swift`
- [ ] Replace `GoldReward` inline constants with `EconomyConfig` references
- [ ] Add merge gold to Stack2048 VM
- [ ] Add merge gold to DropRush VM
- [ ] Add move streak tracker to both VMs
- [ ] Create `AdRewardTracker.swift` with daily cap
- [ ] Create `DailyLoginRewardService.swift`
- [ ] Inject AdRewardTracker + DailyLoginRewardService into AppEnvironment
- [ ] Add persistence keys for streak/login/ad-count data
- [ ] Fire analytics events for all new gold sources

## Success Criteria
- Merge 2→4: +10 gold; merge 512→1024: +512 gold (capped)
- Every 5 moves: +5 gold toast fires
- Watching >5 ads/day: no gold granted (cap enforced)
- Day 1 login: +100 gold; day 7: +400 gold + 1 diamond
- All rewards visible via GoldRewardToast
