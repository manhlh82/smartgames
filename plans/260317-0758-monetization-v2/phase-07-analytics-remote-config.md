# Phase 07 — Analytics & Remote Config

**Priority:** Medium
**Status:** Completed
**Depends on:** Phases 01–06 (instruments all prior work)

## Overview
Add KPI-level analytics events across the full monetization funnel, consolidate all economy values into a remote-config-ready struct, and document A/B test variants for continue price and Starter Pack.

## Related Code Files
- **Modify:** `SmartGames/SharedServices/Analytics/AnalyticsEvent+Gold.swift` — add new gold source events
- **Modify:** `SmartGames/SharedServices/Analytics/AnalyticsEvent+Ads.swift` — add funnel events
- **Create:** `SmartGames/SharedServices/Analytics/AnalyticsEvent+Diamond.swift` — diamond lifecycle
- **Create:** `SmartGames/SharedServices/Analytics/AnalyticsEvent+Store.swift` — purchase funnel
- **Create:** `SmartGames/SharedServices/Analytics/AnalyticsEvent+Conversion.swift` — CTA impressions/clicks
- **Modify:** `SmartGames/SharedServices/Economy/EconomyConfig.swift` — mark all values as remote-overridable
- **Create:** `SmartGames/SharedServices/Economy/RemoteEconomyConfig.swift` — fetch + override layer

## KPI Events Required

### Gold Funnel
```swift
// New sources to add to AnalyticsEvent+Gold.swift
goldEarned(amount: Int, source: GoldSource, balanceAfter: Int)

enum GoldSource: String {
    case mergeReward        // per-tile merge
    case moveStreak         // every 5 moves
    case adWatch            // rewarded ad
    case dailyLogin         // login reward
    case socialShare        // share reward
    case levelComplete      // existing
    case purchaseGrant      // IAP gold pack (future)
}
```

### Diamond Funnel
```swift
// AnalyticsEvent+Diamond.swift
diamondEarned(amount: Int, source: DiamondSource, balanceAfter: Int)
diamondSpent(amount: Int, reason: DiamondSpendReason, balanceAfter: Int)
diamondDropRolled(tileValue: Int, didDrop: Bool)  // for tuning 0.5% rate

enum DiamondSource: String {
    case bigMergeDrop       // 0.5% chance
    case adWatchDrop        // 0.2% chance
    case weeklyChallenge
    case dailyLoginDay7
    case iapGrant           // diamond pack purchase
    case piggyBankUnlock
    case starterPack
}

enum DiamondSpendReason: String {
    case continueFullRevive
    case undoMove
    case cosmeticPurchase
    case skipAdsSingleSession
}
```

### Ad Funnel
```swift
// Add to AnalyticsEvent+Ads.swift
adRewardGranted(outcome: String, context: String)   // "gold_50", "continue", "undo", "diamond_1"
adCapReached(dailyCount: Int)
skipAdsCTAShown(sessionAdCount: Int)
skipAdsCTATapped(action: String)                    // "use_diamonds" | "buy_pass"
removeAdsBannerShown(dailyAdCount: Int)
removeAdsBannerTapped()
```

### Store / Purchase Funnel
```swift
// AnalyticsEvent+Store.swift
storeOpened(tab: String, source: String)            // source: "toolbar" | "death_popup" | "nudge"
productImpression(productID: String)
purchaseStarted(productID: String)
purchaseCompleted(productID: String, revenueUSD: Double)
purchaseFailed(productID: String, reason: String)
purchaseRestored(productID: String)
```

### Conversion CTA Events
```swift
// AnalyticsEvent+Conversion.swift
starterPackShown(trigger: String)                   // "first_loss" | "5min_timer"
starterPackTapped(action: String)                   // "purchase" | "dismiss"
deathPopupShown(hasDiamonds: Bool)
deathPopupCTATapped(choice: String)                 // "watch_ad" | "use_diamonds" | "quit"
timedSaleShown(consecutiveLosses: Int)
timedSaleTapped(action: String)                     // "buy" | "dismiss"
piggyBankNudgeShown(fillPercent: Double)
dailyLoginShown(streakDay: Int)
```

## Remote Config Layer

### EconomyConfig — mark as overridable
All values in `EconomyConfig` become defaults; `RemoteEconomyConfig` fetches overrides.

```swift
// RemoteEconomyConfig.swift
// Wraps EconomyConfig; values fetched from remote (Firebase Remote Config / custom endpoint)
// Falls back to EconomyConfig static defaults if fetch fails

@MainActor
final class RemoteEconomyConfig: ObservableObject {
    // A/B test variants
    @Published var continueDiamondCost: Int = EconomyConfig.continueDiamondCost     // default: 2
    @Published var starterPackDiamondCount: Int = 50
    @Published var mergeBaseGold: Int = EconomyConfig.mergeBaseGold                 // default: 10
    @Published var adWatchGold: Int = EconomyConfig.adWatchGold                     // default: 50
    @Published var adWatchDailyMax: Int = EconomyConfig.adWatchDailyMax             // default: 5
    @Published var bigMergeDropChance: Double = DiamondReward.bigMergeDropChance    // default: 0.005
    @Published var adDiamondChance: Double = EconomyConfig.adDiamondChance          // default: 0.002

    func fetch() async {
        // TODO: integrate Firebase Remote Config or custom config endpoint
        // On success: update published vars
        // On failure: retain defaults silently
    }
}
```

### A/B Test Variants
| Test | Variant A | Variant B | KPI |
|------|-----------|-----------|-----|
| Continue price | 1 diamond | 2 diamonds | continue rate, diamond spend |
| Starter Pack | 50 ◆ + theme ($2.99) | 100 ◆ + 2 themes ($4.99) | conversion rate, ARPU |
| Merge gold base | 5 gold | 10 gold | session length, ad-watch rate |

- Assign variant on first launch; persist in `UserDefaults`
- Log variant assignment as analytics event: `abTestAssigned(test:variant:)`
- All variant values flow through `RemoteEconomyConfig`

## Implementation Steps
1. Create `AnalyticsEvent+Diamond.swift` with full enum
2. Create `AnalyticsEvent+Store.swift` with purchase funnel events
3. Create `AnalyticsEvent+Conversion.swift` with CTA impression/tap events
4. Update `AnalyticsEvent+Gold.swift` — replace `source: String` with `GoldSource` enum
5. Update `AnalyticsEvent+Ads.swift` — add reward outcome + cap events
6. Create `RemoteEconomyConfig.swift` — published vars + `fetch()` stub
7. Inject `RemoteEconomyConfig` into AppEnvironment; call `fetch()` on app launch
8. Replace direct `EconomyConfig` constant reads in VMs with `remoteConfig.xxx`
9. Add `abTestAssigned(test:variant:)` event; fire on first launch
10. Document KPI dashboard requirements (which events map to which metrics)

## KPI Dashboard Mapping
| KPI | Event(s) |
|-----|---------|
| Ad-watch → IAP uplift | `adRewardGranted` + `purchaseCompleted` within same session |
| Time to first purchase | `appFirstOpen` → `purchaseCompleted` delta |
| Continue conversion | `deathPopupShown` → `deathPopupCTATapped(choice:"use_diamonds")` |
| Starter pack conversion | `starterPackShown` → `starterPackTapped(action:"purchase")` |
| LTV by cohort | `purchaseCompleted.revenueUSD` grouped by install week |
| Diamond economy health | `diamondEarned` vs `diamondSpent` ratio over time |

## Todo
- [ ] Create `AnalyticsEvent+Diamond.swift`
- [ ] Create `AnalyticsEvent+Store.swift`
- [ ] Create `AnalyticsEvent+Conversion.swift`
- [ ] Update `AnalyticsEvent+Gold.swift` — typed GoldSource enum
- [ ] Update `AnalyticsEvent+Ads.swift` — reward outcome + cap events
- [ ] Create `RemoteEconomyConfig.swift` with all overridable values
- [ ] Inject RemoteEconomyConfig into AppEnvironment
- [ ] Call `remoteConfig.fetch()` on app launch
- [ ] Replace EconomyConfig direct reads with remoteConfig in VMs
- [ ] Add A/B test assignment event on first launch
- [ ] Document KPI → event mapping in `docs/monetization-kpis.md`

## Success Criteria
- All gold/diamond earn/spend events fire with correct source/reason/balance
- Purchase funnel events (impression → start → complete/fail) present in analytics
- All conversion CTAs (death popup, starter pack, timed sale) log impression + tap
- `RemoteEconomyConfig.fetch()` gracefully falls back to defaults on failure
- A/B variant assigned once, persisted, and logged on first launch
- KPI dashboard can be built from logged events without extra instrumentation
