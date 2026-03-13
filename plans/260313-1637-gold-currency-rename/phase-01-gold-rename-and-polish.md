# Phase 01 — Gold Rename & UI Polish

## Context Links

- [CurrencyService.swift](../../SmartGames/SharedServices/Currency/CurrencyService.swift)
- [CoinBalanceView.swift](../../SmartGames/Common/UI/CoinBalanceView.swift)
- [CoinRewardToast.swift](../../SmartGames/Common/UI/CoinRewardToast.swift)
- [PersistenceService.swift](../../SmartGames/SharedServices/Persistence/PersistenceService.swift)
- [AppEnvironment.swift](../../SmartGames/AppEnvironment.swift)
- [ThemePickerView.swift](../../SmartGames/SharedServices/Settings/ThemePickerView.swift)

## Overview

- **Priority:** P2
- **Status:** Complete
- **Effort:** ~2h
- Single phase covering: identifier rename, file rename, persistence migration, UI text, analytics, comments, tests.
- **Completed:** 2026-03-13

## Rename Map (old -> new)

### Types & Enums

| Old | New |
|-----|-----|
| `CurrencyService` | `GoldService` |
| `CurrencyReward` | `GoldReward` |
| `CoinBalanceView` | `GoldBalanceView` |
| `CoinRewardToast` | `GoldRewardToast` |

### Properties & Variables

| Old | New | File(s) |
|-----|-----|---------|
| `currency` (property on AppEnvironment) | `gold` | AppEnvironment.swift |
| `currency` (@EnvironmentObject) | `gold` | SettingsView, ThemePickerView, CoinBalanceView |
| `currencyService` (property) | `goldService` | ThemeService, SudokuGameViewModel, DropRushGameViewModel |
| `coinsEarnedOnWin` | `goldEarnedOnWin` | SudokuGameViewModel, DropRushGameViewModel |
| `coinsEarned` (param/let) | `goldEarned` | SudokuWinView, SudokuGameView, DropRushResultOverlay, DropRushGameView |
| `showCoinToast` | `showGoldToast` | SudokuWinView, DropRushResultOverlay |
| `baseCoins` / `bonusCoins` / `totalCoins` | `baseGold` / `bonusGold` / `totalGold` | SudokuGameViewModel, DropRushGameViewModel |

### Persistence Keys

| Old | New |
|-----|-----|
| `PersistenceService.Keys.currencyBalance` = `"app.currency.balance"` | `Keys.goldBalance` = `"app.gold.balance"` |

### Analytics Event Strings

| Old | New |
|-----|-----|
| `"currency_earned"` | `"gold_earned"` |
| `"currency_spent"` | `"gold_spent"` |
| `currencyEarned(...)` | `goldEarned(...)` |
| `currencySpent(...)` | `goldSpent(...)` |

### UI Text

| Old | New | File |
|-----|-----|------|
| `"+\(amount) coins"` | `"+\(amount) Gold"` | CoinRewardToast (-> GoldRewardToast) |
| `"\(currency.balance) coins available"` (a11y) | `"\(gold.balance) Gold"` | CoinBalanceView (-> GoldBalanceView) |
| `"+\(amount) coins earned"` (a11y) | `"+\(amount) Gold earned"` | CoinRewardToast |
| `"You have \(currency.balance) coins."` | `"You have \(gold.balance) Gold."` | ThemePickerView |
| `"Not Enough Coins"` | `"Not Enough Gold"` | ThemePickerView |
| `"You need \(deficit) more coins to unlock..."` | `"You need \(deficit) more Gold to unlock..."` | ThemePickerView |
| `"Unlock ... for \(theme.price) coins?"` | `"Unlock ... for \(theme.price) Gold?"` | ThemePickerView |
| `"Locked, \(name.price) coins"` (a11y) | `"Locked, \(name.price) Gold"` | ThemePickerView |
| `Text("Coins")` | `Text("Gold")` | SettingsView |

### Comments / Doc Strings (update "coin" -> "Gold" / "gold")

All files listed below contain comments referencing "coin" or "currency":
- CurrencyService.swift (-> GoldService.swift) — all MARK and doc comments
- ThemeService.swift — "coin-based purchases" -> "Gold-based purchases"
- BoardTheme.swift — "coin purchase" -> "Gold purchase"
- BoardThemePalettes.swift — "50 coins" -> "50 Gold" etc. in doc comments
- SudokuGameViewModel.swift — "coin rewards" -> "Gold rewards"
- DropRushGameViewModel.swift — "coin reward" -> "Gold reward"

### File Renames

| Old Path | New Path |
|----------|----------|
| `SmartGames/SharedServices/Currency/CurrencyService.swift` | `SmartGames/SharedServices/Gold/GoldService.swift` |
| `SmartGames/Common/UI/CoinBalanceView.swift` | `SmartGames/Common/UI/GoldBalanceView.swift` |
| `SmartGames/Common/UI/CoinRewardToast.swift` | `SmartGames/Common/UI/GoldRewardToast.swift` |
| `SmartGames/SharedServices/Analytics/AnalyticsEvent+Currency.swift` | `SmartGames/SharedServices/Analytics/AnalyticsEvent+Gold.swift` |

Update Xcode project `project.pbxproj` references accordingly (or use Xcode rename refactor).

## Files to Modify (complete list, 18 files)

1. **GoldService.swift** (was CurrencyService.swift) — rename type + enum + comments
2. **GoldBalanceView.swift** (was CoinBalanceView.swift) — rename struct, `@EnvironmentObject var gold: GoldService`, update a11y text
3. **GoldRewardToast.swift** (was CoinRewardToast.swift) — rename struct, update UI text + a11y
4. **AnalyticsEvent+Gold.swift** (was +Currency.swift) — rename methods + event strings
5. **PersistenceService.swift** — rename key constant, add migration helper
6. **AppEnvironment.swift** — `let gold: GoldService`, update init
7. **SmartGamesApp.swift** — `.environmentObject(environment.gold)`
8. **ThemeService.swift** — `private let goldService: GoldService`, update init + purchase + comments
9. **ThemePickerView.swift** — `@EnvironmentObject var gold: GoldService`, all UI text
10. **SettingsView.swift** — `@EnvironmentObject var gold: GoldService`, `Text("Gold")`, `GoldBalanceView()`
11. **SudokuGameViewModel.swift** — `goldService`, `goldEarnedOnWin`, local vars, analytics call, comments
12. **SudokuGameView.swift** — `goldEarned:` parameter label, `goldService:` init param
13. **SudokuWinView.swift** — `goldEarned`, `showGoldToast`, `GoldRewardToast`
14. **SudokuModule.swift** — `goldService: environment.gold`
15. **DropRushGameViewModel.swift** — same as SudokuGameViewModel pattern
16. **DropRushGameView.swift** — `goldEarned:`, `goldService:` init param
17. **DropRushResultOverlay.swift** — `goldEarned`, `showGoldToast`, `GoldRewardToast`
18. **DropRushModule.swift** — `goldService: environment.gold`
19. **BoardTheme.swift** — comment update only
20. **BoardThemePalettes.swift** — comment update only
21. **SudokuGameViewModelTests.swift** — `goldService: GoldService(persistence: persistence)`
22. **project.pbxproj** — file reference updates for renamed files

## Persistence Key Migration Strategy

GoldService.init must handle migration from old key:

```swift
init(persistence: PersistenceService) {
    self.persistence = persistence
    // Migration: read from old key if new key absent
    if let existing = persistence.load(Int.self, key: PersistenceService.Keys.goldBalance) {
        self.balance = existing
    } else if let legacy = persistence.load(Int.self, key: "app.currency.balance") {
        self.balance = legacy
        persistence.save(legacy, key: PersistenceService.Keys.goldBalance)
        persistence.delete(key: "app.currency.balance")
    } else {
        self.balance = 0
    }
}
```

Key points:
- New installs: no data at either key, balance = 0
- Existing users: data at old key, migrated to new key on first launch, old key deleted
- Post-migration: reads only new key

## Bug Review Findings

1. **Double reward on retry**: SAFE. Both `SudokuGameViewModel.retry()` (line 439) and `DropRushGameViewModel` (line 211) reset `coinsEarnedOnWin = 0` before starting new game. No bug.

2. **ThemeService.purchase()**: SAFE. Calls `currencyService.spend()` which returns false if insufficient — guard prevents unlock. Analytics event `currencySpent` is NOT logged on purchase (only `themePurchased`). Consider adding `goldSpent` event in ThemeService.purchase() for completeness — **optional enhancement**.

3. **isUnlocked for free themes**: SAFE. `isUnlocked()` returns `name.isFree || unlockedThemes.contains(name)`. Free themes (.light, .dark) always return true.

4. **Balance reactivity**: SAFE. `GoldService.balance` is `@Published`, injected as `@EnvironmentObject`. UI updates automatically.

## Implementation Steps

1. **Create directory** `SmartGames/SharedServices/Gold/`
2. **Rename files** (4 files) using `git mv`:
   - `Currency/CurrencyService.swift` -> `Gold/GoldService.swift`
   - `CoinBalanceView.swift` -> `GoldBalanceView.swift`
   - `CoinRewardToast.swift` -> `GoldRewardToast.swift`
   - `AnalyticsEvent+Currency.swift` -> `AnalyticsEvent+Gold.swift`
3. **Remove** empty `Currency/` directory
4. **Update project.pbxproj** — fix all file references for renamed files
5. **Edit GoldService.swift** — rename types, add persistence migration logic
6. **Edit GoldBalanceView.swift** — rename struct, update EnvironmentObject, a11y
7. **Edit GoldRewardToast.swift** — rename struct, update UI text
8. **Edit AnalyticsEvent+Gold.swift** — rename methods + event strings
9. **Edit PersistenceService.swift** — rename key constant
10. **Edit AppEnvironment.swift** — `let gold: GoldService`, update init
11. **Edit SmartGamesApp.swift** — `.environmentObject(environment.gold)`
12. **Edit ThemeService.swift** — `goldService: GoldService`, update init/purchase/comments
13. **Edit ThemePickerView.swift** — all Gold text + EnvironmentObject rename
14. **Edit SettingsView.swift** — Gold text + EnvironmentObject rename
15. **Edit SudokuGameViewModel.swift** — all property/variable/analytics renames
16. **Edit SudokuGameView.swift** — parameter label updates
17. **Edit SudokuWinView.swift** — property + toast renames
18. **Edit SudokuModule.swift** — `goldService: environment.gold`
19. **Edit DropRushGameViewModel.swift** — same pattern as Sudoku VM
20. **Edit DropRushGameView.swift** — parameter label updates
21. **Edit DropRushResultOverlay.swift** — property + toast renames
22. **Edit DropRushModule.swift** — `goldService: environment.gold`
23. **Edit BoardTheme.swift** — comment only
24. **Edit BoardThemePalettes.swift** — comments only
25. **Edit SudokuGameViewModelTests.swift** — update init call
26. **Build & verify** — `xcodebuild build` to catch any missed references
27. **Search sweep** — grep for any remaining `coin`/`currency` references in Swift files

## Todo List

- [x] Rename files with `git mv` (4 files)
- [x] Update project.pbxproj references
- [x] Rename types: CurrencyService->GoldService, CurrencyReward->GoldReward
- [x] Add persistence key migration in GoldService.init
- [x] Rename all properties and variables (see map above)
- [x] Update all UI text strings from coins -> Gold
- [x] Update analytics event names and methods
- [x] Update all doc comments and MARK comments
- [x] Update EnvironmentObject references across views
- [x] Update test file
- [x] Build and verify no compile errors
- [x] Final grep sweep for leftover coin/currency references

## Success Criteria

- Zero references to "coin" or "currency" in Swift files (except generic English words in unrelated contexts)
- App builds without errors
- Existing user balance preserved via key migration
- All UI shows "Gold" branding
- Theme picker header shows balance with "Gold" label
- Settings shows "Gold" row with balance
- Win screens show "+X Gold" toast
- Analytics events fire with `gold_earned` / `gold_spent` names

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Missed reference causes compile error | Low | Final grep sweep + build |
| Existing users lose balance | Medium | Migration logic reads old key, writes new, deletes old |
| project.pbxproj corruption | Low | Use `git mv` then fix references carefully; build to verify |

## Security Considerations

None — no auth, network, or sensitive data changes.
