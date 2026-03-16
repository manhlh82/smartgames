# Phase 01 — Per-Game Monetization Config Model

**Priority:** P1 | **Effort:** 2h | **PR:** PR-11

---

## Context Links
- [GameModule.swift](../../SmartGames/Core/GameModule.swift) -- protocol to extend
- [SudokuModule.swift](../../SmartGames/Games/Sudoku/SudokuModule.swift) -- first adopter
- [AdsConfig.swift](../../SmartGames/SharedServices/Ads/AdsConfig.swift) -- current hardcoded config to replace
- [AdsService.swift](../../SmartGames/SharedServices/Ads/AdsService.swift) -- consumer of config

---

## Overview

Create a `MonetizationConfig` struct that each game provides via `GameModule`. Replaces hardcoded `AdsConfig` static lets with per-game configurable values. Future games (Block Puzzle, Parking Jam) provide their own config without touching shared code.

---

## MonetizationConfig Struct

```swift
// SharedServices/Ads/MonetizationConfig.swift

/// Per-game monetization configuration.
/// Each GameModule provides its own instance; AdsService reads it at runtime.
struct MonetizationConfig {
    // MARK: - Banner
    var bannerEnabled: Bool = true
    // Note: banner refresh interval is controlled by AdMob SDK/dashboard, not app-side code.

    // MARK: - Post-level Interstitial
    var interstitialEnabled: Bool = true
    /// Show interstitial every N completed levels. 1 = every level.
    var interstitialFrequency: Int = 1

    // MARK: - Rewarded Hints
    var rewardedHintsEnabled: Bool = true
    /// Hints granted per rewarded ad watch.
    var rewardedHintAmount: Int = 3
    /// Hints granted on level completion.
    var levelCompleteHintReward: Int = 1
    /// Maximum hint balance (never exceed).
    var maxHintCap: Int = 3

    // MARK: - Rewarded Mistake Reset
    var mistakeResetEnabled: Bool = true
    /// Max mistake resets allowed per level.
    var mistakeResetUsesPerLevel: Int = 1
}
```

**Design notes:**
- Plain struct, `Sendable`-conforming (all value types)
- Defaults match Sudoku requirements; other games override as needed
- No Codable yet (YAGNI) -- add when remote config is introduced

---

## GameModule Protocol Extension

Add optional `monetizationConfig` property with default:

```swift
// In GameModule.swift — add to protocol
var monetizationConfig: MonetizationConfig { get }

// Default implementation (extension)
extension GameModule {
    var monetizationConfig: MonetizationConfig { MonetizationConfig() }
}
```

Games that need custom config override in their module:

```swift
// In SudokuGameModule
var monetizationConfig: MonetizationConfig {
    MonetizationConfig(
        bannerEnabled: true,
        interstitialEnabled: true,
        interstitialFrequency: 1,
        rewardedHintsEnabled: true,
        rewardedHintAmount: 3,
        levelCompleteHintReward: 1,
        maxHintCap: 3,
        mistakeResetEnabled: true,
        mistakeResetUsesPerLevel: 1
    )
}
```

---

## AdsConfig Migration

Current `AdsConfig` keeps ad unit IDs (Debug/Release) and gains a `MonetizationConfig` reference:

```swift
// AdsConfig.swift — keep ad unit IDs, remove hardcoded behavior params

enum AdsConfig {
    // Ad unit IDs unchanged
    static var rewardedAdUnitID: String { ... }
    static var interstitialAdUnitID: String { ... }
    static var bannerAdUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2435281174" // Official test banner ID
        #else
        return Bundle.main.object(forInfoDictionaryKey: "ADS_BANNER_ID") as? String
               ?? "ca-app-pub-3940256099942544/2435281174"
        #endif
    }

    // REMOVE: maxInterstitialsPerSession, interstitialCooldownSeconds
    // These are now in MonetizationConfig
}
```

---

## Files to Create

| File | Purpose |
|------|---------|
| `SharedServices/Ads/MonetizationConfig.swift` | Config struct |

## Files to Modify

| File | Change |
|------|--------|
| `Core/GameModule.swift` | Add `var monetizationConfig: MonetizationConfig` with default |
| `Games/Sudoku/SudokuModule.swift` | Override `monetizationConfig` with Sudoku defaults |
| `SharedServices/Ads/AdsConfig.swift` | Add banner ad unit ID; remove `maxInterstitialsPerSession`, `interstitialCooldownSeconds` |

---

## Acceptance Criteria

- [ ] `MonetizationConfig` struct compiles with all required fields
- [ ] `GameModule` protocol has `monetizationConfig` with sensible defaults
- [ ] `SudokuGameModule` provides explicit Sudoku config
- [ ] `AdsConfig` has banner ad unit ID (test + prod)
- [ ] Old hardcoded limits removed from `AdsConfig`
- [ ] Existing interstitial behavior unbroken (InterstitialAdCoordinator reads from config)

## Tests

- Unit: `MonetizationConfig` defaults match expected values
- Unit: `SudokuGameModule().monetizationConfig` returns Sudoku-specific config
- Compile: no regressions in existing ad flow
