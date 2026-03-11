# Phase 5: In-App Purchases (Remove Ads + Hint Packs)

## Context Links
- [AdsService.swift](../../SmartGames/SharedServices/Ads/AdsService.swift) -- ad coordinator to gate
- [SudokuGameViewModel.swift](../../SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift) -- hint system
- [PersistenceService.swift](../../SmartGames/SharedServices/Persistence/PersistenceService.swift) -- hint count storage
- [SettingsView.swift](../../SmartGames/SharedServices/Settings/SettingsView.swift) -- restore purchases UI
- [AppEnvironment.swift](../../SmartGames/AppEnvironment.swift)

## Overview
- **Priority:** P2 -- revenue feature, requires App Store Connect setup
- **Status:** ✅ Complete
- **Effort:** 7h
- **Description:** Two IAP products using StoreKit 2: "Remove Ads" ($2.99 non-consumable) and "Hint Pack" ($0.99 consumable, 10 hints). StoreKit 2 async/await API (iOS 15+).

## Key Insights
- StoreKit 2 (2021+) uses `Product`, `Transaction`, `Product.PurchaseResult` -- all async/await, no delegates
- "Remove Ads" is non-consumable: purchase once, persists via `Transaction.currentEntitlements`
- "Hint Pack" is consumable: each purchase adds 10 hints to `hintsRemaining`
- Current hint system: `hintsRemaining` stored in `PersistenceService` under `sudoku.hints.remaining`
- Current ad system: `AdsService` has `showRewardedAd()` and `showInterstitialIfReady()` -- gate both behind `removeAds` flag
- StoreKit 2 handles receipt validation locally via JWS -- no server-side validation needed
- `Transaction.updates` async sequence must be listened to for interrupted purchases, family sharing, refunds

## Requirements

### Functional
- FR1: "Remove Ads" ($2.99) -- non-consumable, permanently hides all ads (interstitial + rewarded)
- FR2: "Hint Pack" ($0.99) -- consumable, adds 10 hints to balance
- FR3: Purchase UI accessible from Settings ("SmartGames Pro" section)
- FR4: "Restore Purchases" button in Settings
- FR5: Purchased "Remove Ads" state persists and restores on reinstall/new device
- FR6: Hint balance visible in game toolbar (already shown)
- FR7: Purchase prompt in-context: when hint ad prompt appears, show "Buy Hints" option alongside "Watch Ad"

### Non-Functional
- NFR1: Purchases work offline after initial validation
- NFR2: Transaction listener runs for entire app lifecycle
- NFR3: StoreKit Configuration file for testing without App Store Connect

## Architecture

### Product IDs (App Store Connect)
```
com.smartgames.removeads       -- Non-consumable, $2.99
com.smartgames.hintpack10      -- Consumable, $0.99
```

### StoreService
```swift
import StoreKit

@MainActor
final class StoreService: ObservableObject {
    @Published var removeAdsProduct: Product?
    @Published var hintPackProduct: Product?
    @Published var isAdsRemoved: Bool = false
    @Published var isPurchasing: Bool = false

    private var transactionListener: Task<Void, Never>?
    private let persistence: PersistenceService

    init(persistence: PersistenceService) { ... }

    func loadProducts() async
    func purchaseRemoveAds() async throws -> Bool
    func purchaseHintPack() async throws -> Int   // returns new hint balance
    func restorePurchases() async
    func checkEntitlements() async                 // verify remove-ads on launch
}
```

### Integration with AdsService
```swift
// In AdsService or wherever ads are shown:
func showInterstitialIfReady() {
    guard !storeService.isAdsRemoved else { return }
    // existing logic
}

func showRewardedAd(completion:) {
    guard !storeService.isAdsRemoved else {
        completion(true) // auto-grant if ads removed
        return
    }
    // existing logic
}
```

### Transaction Flow
```
App Launch
  → StoreService.init()
  → listenForTransactions()          // Task listening Transaction.updates
  → checkEntitlements()              // verify non-consumable ownership
  → loadProducts()                   // fetch Product metadata for display

Purchase "Remove Ads"
  → Product.purchase()
  → await Transaction verification
  → Transaction.finish()
  → set isAdsRemoved = true
  → persist flag locally as cache

Purchase "Hint Pack"
  → Product.purchase()
  → await Transaction verification
  → Transaction.finish()
  → hintsRemaining += 10
  → save to PersistenceService
```

## Files to Create

| File | Purpose |
|------|---------|
| `SharedServices/Store/StoreService.swift` | StoreKit 2 product loading, purchasing, entitlement checking |
| `SharedServices/Store/StoreProductView.swift` | Reusable product purchase card (icon, price, buy button) |
| `SharedServices/Store/StorePurchaseView.swift` | Full purchase screen / section for Settings |
| `SmartGames/StoreKitConfig.storekit` | StoreKit Configuration file for testing |

## Files to Modify

| File | Change |
|------|--------|
| `AppEnvironment.swift` | Add `let store: StoreService` |
| `SmartGamesApp.swift` | Inject `StoreService`; start transaction listener |
| `SharedServices/Ads/AdsService.swift` | Check `storeService.isAdsRemoved` before showing ads |
| `PersistenceService.swift` | Add keys: `store.adsRemoved` (cache), hint balance already exists |
| `SharedServices/Settings/SettingsView.swift` | Add "SmartGames Pro" section with purchase options + restore |
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | In `needsHintAd` state, offer "Buy Hints" alongside "Watch Ad" |
| `Games/Sudoku/Views/SudokuGameView.swift` | Update hint ad prompt to include purchase option |
| `project.yml` | Add StoreKit capability + config file reference |

## Implementation Steps

1. **Create StoreKit Configuration file**
   - Xcode: File → New → StoreKit Configuration File
   - Add product: `com.smartgames.removeads` (Non-Consumable, $2.99, "Remove Ads")
   - Add product: `com.smartgames.hintpack10` (Consumable, $0.99, "10 Hints")
   - Set as run scheme StoreKit config for testing

2. **Create `StoreService.swift`**
   ```swift
   import StoreKit

   @MainActor
   final class StoreService: ObservableObject {
       @Published var products: [Product] = []
       @Published var isAdsRemoved: Bool = false
       @Published var isPurchasing: Bool = false

       private var transactionListener: Task<Void, Never>?
       private let persistence: PersistenceService
       private let productIDs = ["com.smartgames.removeads", "com.smartgames.hintpack10"]

       var removeAdsProduct: Product? { products.first { $0.id == "com.smartgames.removeads" } }
       var hintPackProduct: Product? { products.first { $0.id == "com.smartgames.hintpack10" } }

       init(persistence: PersistenceService) {
           self.persistence = persistence
           // Load cached ad-removal state
           self.isAdsRemoved = persistence.load(Bool.self, key: "store.adsRemoved") ?? false
           startTransactionListener()
       }

       func loadProducts() async {
           do {
               products = try await Product.products(for: productIDs)
           } catch {
               print("[Store] Failed to load products: \(error)")
           }
       }

       func purchaseRemoveAds() async throws -> Bool {
           guard let product = removeAdsProduct else { return false }
           isPurchasing = true
           defer { isPurchasing = false }

           let result = try await product.purchase()
           switch result {
           case .success(let verification):
               let transaction = try checkVerified(verification)
               await transaction.finish()
               isAdsRemoved = true
               persistence.save(true, key: "store.adsRemoved")
               return true
           case .userCancelled, .pending:
               return false
           @unknown default:
               return false
           }
       }

       func purchaseHintPack() async throws -> Int {
           guard let product = hintPackProduct else { return 0 }
           isPurchasing = true
           defer { isPurchasing = false }

           let result = try await product.purchase()
           switch result {
           case .success(let verification):
               let transaction = try checkVerified(verification)
               await transaction.finish()
               let current = persistence.load(Int.self, key: PersistenceService.Keys.sudokuHintsRemaining) ?? 0
               let newBalance = current + 10
               persistence.save(newBalance, key: PersistenceService.Keys.sudokuHintsRemaining)
               return newBalance
           case .userCancelled, .pending:
               return 0
           @unknown default:
               return 0
           }
       }

       func restorePurchases() async {
           try? await AppStore.sync()
           await checkEntitlements()
       }

       func checkEntitlements() async {
           for await result in Transaction.currentEntitlements {
               if case .verified(let transaction) = result,
                  transaction.productID == "com.smartgames.removeads" {
                   isAdsRemoved = true
                   persistence.save(true, key: "store.adsRemoved")
                   return
               }
           }
       }

       private func startTransactionListener() {
           transactionListener = Task.detached { [weak self] in
               for await result in Transaction.updates {
                   if case .verified(let transaction) = result {
                       await self?.handleTransaction(transaction)
                       await transaction.finish()
                   }
               }
           }
       }

       private func handleTransaction(_ transaction: Transaction) {
           switch transaction.productID {
           case "com.smartgames.removeads":
               if transaction.revocationDate == nil {
                   isAdsRemoved = true
                   persistence.save(true, key: "store.adsRemoved")
               } else {
                   isAdsRemoved = false
                   persistence.save(false, key: "store.adsRemoved")
               }
           default: break
           }
       }

       private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
           switch result {
           case .unverified: throw StoreError.verificationFailed
           case .verified(let safe): return safe
           }
       }

       deinit { transactionListener?.cancel() }
   }

   enum StoreError: Error {
       case verificationFailed
   }
   ```

3. **Wire into `AppEnvironment`**
   - Add `let store: StoreService`
   - Init: `self.store = StoreService(persistence: persistence)`

4. **Update `SmartGamesApp.swift`**
   - Add `.environmentObject(environment.store)`
   - In `.task`: `await environment.store.loadProducts()`

5. **Update `AdsService`**
   - Option A: Pass `StoreService` reference and check `isAdsRemoved`
   - Option B: `AdsService` reads a `@Published var adsDisabled: Bool` set by AppEnvironment
   - Recommended: Option B (loose coupling). AppEnvironment observes `store.isAdsRemoved` and sets `ads.adsDisabled`

6. **Create `StoreProductView.swift`**
   - Card showing product name, description, price
   - "Buy" button with loading state
   - Checkmark if already purchased (for remove ads)

7. **Create `StorePurchaseView.swift`**
   - Section for Settings with both products
   - "Restore Purchases" button

8. **Update `SettingsView.swift`**
   - Add "SmartGames Pro" section above "Gameplay"
   - Embed `StorePurchaseView` or inline the product cards

9. **Update hint ad flow**
   - In `SudokuGameViewModel` when `gamePhase == .needsHintAd`:
     - Show 3 options: "Watch Ad" (existing), "Buy 10 Hints ($0.99)", "Cancel"
   - Update the corresponding view to show the additional button

10. **Add persistence key**
    - `PersistenceService.Keys`: add `static let storeAdsRemoved = "store.adsRemoved"`

11. **App Store Connect setup** (manual)
    - Create app IAP products matching IDs
    - Set pricing
    - Submit for review alongside app update

## Todo List

- [ ] Create StoreKit Configuration file for local testing
- [ ] Create `StoreService` with product loading, purchase, restore
- [ ] Wire into `AppEnvironment` and `SmartGamesApp`
- [ ] Inject `StoreService` as environment object
- [ ] Gate ads behind `isAdsRemoved` check in `AdsService`
- [ ] Create `StoreProductView` reusable card
- [ ] Create `StorePurchaseView` for Settings
- [ ] Add "SmartGames Pro" section to `SettingsView`
- [ ] Update hint ad prompt with "Buy Hints" option
- [ ] Add "Restore Purchases" flow
- [ ] Handle transaction listener for interrupted purchases and refunds
- [ ] Add persistence key for ads-removed cache
- [ ] Test purchase flow with StoreKit Configuration
- [ ] Test restore purchases flow
- [ ] Test refund handling (revocation)
- [ ] Create products in App Store Connect

## Acceptance Criteria

- [ ] "Remove Ads" purchase hides all ads immediately
- [ ] "Remove Ads" state survives app reinstall (via `Transaction.currentEntitlements`)
- [ ] "Hint Pack" adds exactly 10 hints to balance
- [ ] Multiple hint pack purchases stack (10 + 10 = 20)
- [ ] "Restore Purchases" recovers "Remove Ads" on new device
- [ ] Refund/revocation re-enables ads
- [ ] Purchase flow handles cancel, pending, and error states gracefully
- [ ] Products display localized prices
- [ ] Settings shows purchase options with correct state (purchased/available)
- [ ] Hint ad prompt shows "Buy Hints" option alongside "Watch Ad"

## Tests Needed

- `StoreService`: mock `Product.products(for:)` -- verify products loaded
- `StoreService`: verify `isAdsRemoved` persists and restores from cache
- `StoreService`: verify hint balance increments by 10 on consumable purchase
- `StoreService`: verify revocation handling sets `isAdsRemoved = false`
- `AdsService`: verify ads gated when `isAdsRemoved == true`
- StoreKit Configuration file: end-to-end purchase flow in simulator
- Edge case: purchase while offline, then come online

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| StoreKit sandbox instability | Medium | Use StoreKit Configuration file for dev; test sandbox on device before submission |
| Receipt verification edge cases | Low | StoreKit 2 handles JWS verification automatically |
| Family Sharing complications for non-consumable | Low | StoreKit 2 handles this; test with family sharing sandbox |
| Price localization display issues | Low | Use `product.displayPrice` (auto-localized by StoreKit) |
| Hint balance desync between IAP and rewarded ads | Medium | Single source of truth: `PersistenceService.Keys.sudokuHintsRemaining` |

## Security Considerations
- StoreKit 2 verifies transactions via JWS -- no custom receipt validation needed
- `adsRemoved` local cache is convenience only; `Transaction.currentEntitlements` is source of truth
- No server-side component -- acceptable for indie app scale
- Consumable purchases cannot be restored (by design) -- document for users

## Next Steps
- Premium themes IAP (Phase 3+): additional non-consumable for theme packs
- Subscription model evaluation if daily content warrants it
- Server-side receipt validation if fraud becomes an issue
