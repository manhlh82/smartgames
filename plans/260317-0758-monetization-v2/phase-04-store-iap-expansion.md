# Phase 04 — Store & IAP Expansion

**Priority:** High
**Status:** Completed
**Depends on:** Phase 01 (DiamondService)

## Overview
Expand StoreService with diamond IAP products (diamond packs, Starter Pack, skip-ads 24h pass). Add Piggy Bank mechanic. Expand PaywallView into a tabbed store with Gold Items / Premium (Diamonds) sections and cosmetic rarity tiers.

## Related Code Files
- **Modify:** `SmartGames/SharedServices/Store/StoreService.swift` — add new product IDs + entitlement tracking
- **Modify:** `SmartGames/Games/Sudoku/Views/PaywallView.swift` — replace with tabbed store (or extract to shared)
- **Create:** `SmartGames/SharedServices/Store/StoreView.swift` — shared tabbed store (Gold / Premium tabs)
- **Create:** `SmartGames/SharedServices/Store/PiggyBankService.swift` — fractional diamond accumulation
- **Create:** `SmartGames/SharedServices/Store/StarterPackService.swift` — tracks offer shown/claimed state
- **Modify:** `SmartGames/SharedServices/Persistence/PersistenceService.swift` — keys for piggy bank, starter pack state
- **Modify:** `SmartGames/SharedServices/Analytics/AnalyticsEvent+Store.swift` (create if absent) — purchase funnel events

## New Product IDs
```swift
// Add to StoreService
static let starterPackID     = "com.smartgames.starterpack"    // 50 diamonds + exclusive theme, one-time
static let diamondPack1ID    = "com.smartgames.diamonds.50"    // 50 diamonds
static let diamondPack2ID    = "com.smartgames.diamonds.100"   // 100 diamonds (best value badge)
static let skipAds24hID      = "com.smartgames.skipads.24h"    // $0.99 consumable, 24h ad suppression
static let piggyBankID       = "com.smartgames.piggybank"      // unlock accumulated diamonds
```

## Cosmetic Rarity Tiers
```swift
enum CosmeticRarity {
    case common     // gold only (≤1000 gold)
    case rare       // gold or diamonds (500–800 gold / 5–10 diamonds)
    case legendary  // diamonds only (20–50 diamonds)
}
```
- Theme model gains `rarity: CosmeticRarity` and `diamondPrice: Int?`
- Store "Premium" tab filters `.rare` + `.legendary` items; shows "Exclusive" badge

## Piggy Bank Mechanic
`PiggyBankService`:
- `fractionalDiamonds: Double` — increments by 0.1 per game completed, 0.05 per ad watched
- When `fractionalDiamonds >= 10.0`: piggy bank is "full" → show unlock CTA in store
- Purchase `piggyBankID`: grant `floor(fractionalDiamonds)` diamonds, reset to 0
- Progress bar shown in store header (e.g. "7.3 / 10 diamonds saved")
- Persist `fractionalDiamonds` across sessions

## Starter Pack
`StarterPackService`:
- `hasBeenOffered: Bool` (persist)
- `hasBeenClaimed: Bool` (persist)
- Offer conditions: first game loss OR session time ≥ 5 min (Phase 06 handles trigger)
- Contents: 50 diamonds + one exclusive theme unlock
- One-time purchase only; hide after claimed

## Skip Ads 24h Pass
- `StoreService` tracks `skipAdsExpiry: Date?` (persist)
- `var isSkipAdsActive: Bool { skipAdsExpiry.map { $0 > Date() } ?? false }`
- On purchase: `skipAdsExpiry = Date().addingTimeInterval(86400)`
- Show offer after 5 ad-watches in a session (surfaced in Phase 06)

## StoreView Structure
```
StoreView (tabbed)
├── Tab "Gold Items"
│   ├── ThemeGrid (common + rare gold-purchasable)
│   └── HintPackRow (existing)
└── Tab "Premium ◆"
    ├── PiggyBankBanner (progress bar + unlock CTA)
    ├── DiamondPacksGrid (50 / 100 diamonds)
    ├── StarterPackRow (if not claimed)
    ├── SkipAdsPassRow
    └── ThemeGrid (rare + legendary diamond items, "Exclusive" badge)
```

## Implementation Steps
1. Add new product ID constants to `StoreService`
2. Extend `updateEntitlements()` to track `skipAdsExpiry`, `piggyBankUnlocked`
3. Create `PiggyBankService.swift` with fractional accumulation + persistence
4. Create `StarterPackService.swift` with offer/claim state
5. Add `CosmeticRarity` to theme models; tag existing themes as `common`
6. Create shared `StoreView.swift` with Gold / Premium tabs
7. Replace Sudoku-specific `PaywallView` with shared `StoreView` (or embed it)
8. Wire piggy bank increments: game completion → +0.1, ad watch → +0.05
9. Inject `PiggyBankService` + `StarterPackService` into AppEnvironment
10. Add store analytics: `storeOpened(tab:)`, `productImpression(id:)`, `purchaseStarted(id:)`, `purchaseCompleted(id:revenue:)`

## Todo
- [ ] Add new product ID constants
- [ ] Extend StoreService entitlement tracking (skipAds expiry, piggy bank)
- [ ] Create `PiggyBankService.swift`
- [ ] Create `StarterPackService.swift`
- [ ] Add `CosmeticRarity` + `diamondPrice` to theme model
- [ ] Create shared `StoreView.swift` (Gold + Premium tabs)
- [ ] Migrate PaywallView to use StoreView
- [ ] Wire piggy bank increments from game VMs
- [ ] Inject new services into AppEnvironment
- [ ] Add purchase funnel analytics

## Success Criteria
- Store shows two tabs; premium items have "Exclusive" badge
- Piggy bank fills with play, shows progress bar, unlocks on purchase
- Starter Pack appears once per install; grants 50 diamonds + theme
- Skip ads pass suppresses interstitial + banner for 24h after purchase
- Diamond packs grant correct amounts via StoreKit2 verified transaction
