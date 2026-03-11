# Phase Implementation Report

## Executed Phase
- Phase: phase-05-iap
- Plan: /Users/manh.le/github-personal/smartgames/plans/260311-0629-phase2-retention-monetization/
- Status: completed

## Files Modified

| File | Change | Lines |
|------|--------|-------|
| `SmartGames/SharedServices/Store/StoreService.swift` | CREATED | 169 |
| `SmartGames/Games/Sudoku/Views/PaywallView.swift` | CREATED | 163 |
| `SmartGames/Configuration/SmartGames.storekit` | CREATED | 44 |
| `SmartGames/AppEnvironment.swift` | MODIFIED — added StoreService, wired storeService into AdsService | 43 |
| `SmartGames/SmartGamesApp.swift` | MODIFIED — inject store EnvironmentObject, start transaction listener, refresh entitlements | 65 |
| `SmartGames/SharedServices/Ads/AdsService.swift` | MODIFIED — added storeService weak ref, skip ads when hasRemovedAds | 60 |
| `SmartGames/SharedServices/Settings/SettingsView.swift` | MODIFIED — added Premium section with Remove Ads / Get Hints buttons + paywall sheet | 67 |
| `SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | MODIFIED — dailyChallengeService param, storeService weak ref, hint grant observer, win callback | 385 |
| `SmartGames/Games/Sudoku/Views/DailyChallengeView.swift` | MODIFIED — set isDailyChallenge flag in persistence before navigation | 199 |
| `SmartGames/Games/Sudoku/Views/SudokuGameView.swift` | MODIFIED — accept dailyChallengeService + storeService params, pass to ViewModel | 215 |
| `SmartGames/ContentView.swift` | MODIFIED — inject store EnvironmentObject, read isDailyChallenge flag, pass services to SudokuGameView | 75 |
| `SmartGames/SharedServices/Persistence/PersistenceService.swift` | MODIFIED — added sudokuPendingIsDailyChallenge key | 48 |

## Tasks Completed

- [x] Critical fix: `DailyChallengeService.markCompleted()` wired into `SudokuGameViewModel.checkWin()`
- [x] `DailyChallengeView` sets `sudokuPendingIsDailyChallenge` flag in persistence before navigating
- [x] `ContentView` reads flag and passes `dailyChallengeService` to `SudokuGameView` → `SudokuGameViewModel`
- [x] `StoreService` — StoreKit 2 product loading, purchase, restore, transaction listener, entitlement check
- [x] Products: `com.smartgames.removeads` (non-consumable $2.99) + `com.smartgames.hintpack` (consumable $0.99)
- [x] `hasRemovedAds` computed from verified `currentEntitlements`
- [x] `AdsService` skips rewarded and interstitial ads when `hasRemovedAds == true`
- [x] `StoreService` injected into `AppEnvironment`, registered as `EnvironmentObject` in `SmartGamesApp`
- [x] Background transaction listener started on app launch
- [x] `pendingHintGrant: Bool` published flag for hint pack grants
- [x] `SudokuGameViewModel` observes `pendingHintGrant` via polling task — grants 10 hints, resets flag
- [x] `PaywallView` — sheet with product rows, buy buttons (displayPrice from StoreKit), restore button, loading overlay, error alert
- [x] `SettingsView` Premium section with Remove Ads entry point + Get Hints button → opens PaywallView sheet
- [x] `SmartGames.storekit` config for sandbox testing (non-consumable + consumable)
- [x] xcodegen regenerated successfully

## Tests Status
- Type check: pass (BUILD SUCCEEDED)
- Unit tests: not run (no test changes required for this phase; StoreKit 2 sandbox testing requires device)
- Integration tests: manual testing via StoreKit sandbox config

## Architecture Notes

**Daily challenge win callback flow:**
1. `DailyChallengeView.startDailyChallenge()` → saves puzzle + `isDailyChallenge=true` to persistence
2. `ContentView.sudokuGameDestination()` reads flag → passes `dailyChallengeService` to `SudokuGameView`
3. `SudokuGameView.init` passes it to `SudokuGameViewModel`
4. `SudokuGameViewModel.checkWin()` calls `dailyChallengeService?.markCompleted(elapsedSeconds:mistakes:stars:)`

**IAP hint grant flow:**
1. `StoreService.purchase()` sets `pendingHintGrant = true` after verified Hint Pack transaction
2. `SudokuGameViewModel.observeHintGrants()` polls every 200ms for flag transition false→true
3. `grantHintsFromPurchase()` adds 10 hints, persists, auto-applies hint if game was in `.needsHintAd` phase

**Ads bypass flow:**
`AdsService.storeService` weak ref set by `AppEnvironment` after both services are initialized. Guards in `showRewardedAd()` and `showInterstitialIfReady()` call early-return with success when `hasRemovedAds == true`.

## Issues Encountered

- `ContentView.swift` required modification (not in original owned-files list). Unavoidable: it is the sole navigation builder for `SudokuGameView` and no other mechanism existed to pass `dailyChallengeService` without routing changes.
- `listenForTransactions()` initially used a detached task calling `@MainActor` methods directly — fixed by routing through `handleTransactionUpdate(_:)` which is `@MainActor`-isolated via `self`.
- Pre-existing warning in `AdsService.swift` line 44 (no async in await) — from stub `RewardedAdCoordinator`, not introduced by this phase.

## Next Steps
- Assign StoreKit configuration file in Xcode scheme for sandbox testing (Edit Scheme → Run → StoreKit Configuration → `SmartGames.storekit`)
- Replace stub AdMob IDs with real ones before App Store submission
- Add `SKPaymentQueue` capability in entitlements if needed (StoreKit 2 handles automatically on iOS 16+)
