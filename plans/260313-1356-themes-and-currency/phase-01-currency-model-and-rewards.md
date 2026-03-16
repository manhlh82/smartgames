# Phase 1: Currency Model & Rewards

## Context Links

- [Plan overview](plan.md)
- [PersistenceService](../../SmartGames/SharedServices/Persistence/PersistenceService.swift)
- [AppEnvironment](../../SmartGames/AppEnvironment.swift)
- [SudokuGameViewModel](../../SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift)
- [DropRushGameViewModel](../../SmartGames/Games/DropRush/ViewModels/DropRushGameViewModel.swift)

## Overview

- **Priority:** P1
- **Status:** completed
- **Description:** Create `CurrencyService`, add persistence keys, wire reward hooks into both game ViewModels at level-complete.

## Key Insights

- `PersistenceService` already supports typed `save/load` with `Codable` -- reuse for currency balance.
- Both game VMs already have a clear level-complete block (Sudoku line ~454, Drop Rush line ~116) where we inject reward calls.
- Currency is a shared concern (cross-game) so it belongs in `AppEnvironment`, not in a `GameModule`.
- Star rating already computed in both VMs -- bonus coins trivially gated on `starRating == 3`.

## Architecture

### CurrencyService Interface

```swift
@MainActor
final class CurrencyService: ObservableObject {
    @Published private(set) var balance: Int  // never negative

    private let persistence: PersistenceService

    init(persistence: PersistenceService)

    /// Add coins. Clamped to Int.max to prevent overflow.
    func earn(amount: Int)

    /// Attempt spend. Returns false if insufficient funds (balance unchanged).
    func spend(amount: Int) -> Bool

    private func save()
    private func load() -> Int
}
```

### Persistence Keys

```swift
extension PersistenceService.Keys {
    static let currencyBalance = "app.currency.balance"  // Int
}
```

### Reward Amounts (constants)

```swift
enum CurrencyReward {
    static let sudokuComplete = 15
    static let sudokuThreeStarBonus = 10
    static let dropRushComplete = 10
    static let dropRushThreeStarBonus = 10
}
```

Place `CurrencyReward` in the same file as `CurrencyService` (under 200 lines total).

### Analytics Events

```swift
extension AnalyticsEvent {
    static func currencyEarned(amount: Int, source: String, balanceAfter: Int) -> AnalyticsEvent
    static func currencySpent(amount: Int, item: String, balanceAfter: Int) -> AnalyticsEvent
}
```

New file: `AnalyticsEvent+Currency.swift`.

## Related Code Files

### Modify

| File | Change |
|------|--------|
| `SmartGames/SharedServices/Persistence/PersistenceService.swift` | Add `currencyBalance` key |
| `SmartGames/AppEnvironment.swift` | Create + inject `CurrencyService` |
| `SmartGames/SmartGamesApp.swift` | Add `.environmentObject(env.currency)` to view tree |
| `SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Accept `CurrencyService`, call `earn()` at win |
| `SmartGames/Games/Sudoku/SudokuModule.swift` | Pass `currencyService` to game view |
| `SmartGames/Games/DropRush/ViewModels/DropRushGameViewModel.swift` | Accept `CurrencyService`, call `earn()` at levelComplete |
| `SmartGames/Games/DropRush/DropRushModule.swift` | Pass `currencyService` to game view |

### Create

| File | Purpose |
|------|---------|
| `SmartGames/SharedServices/Currency/CurrencyService.swift` | Currency balance + earn/spend logic |
| `SmartGames/SharedServices/Analytics/AnalyticsEvent+Currency.swift` | Currency analytics events |

## Implementation Steps

1. Create `SmartGames/SharedServices/Currency/CurrencyService.swift`
   - Define `CurrencyService` class with `balance`, `earn()`, `spend()`, persistence load/save
   - Define `CurrencyReward` enum with static constants
   - `earn()`: clamp at `Int.max` via `addingReportingOverflow`; save after mutation
   - `spend()`: return `false` if `amount > balance`; subtract and save if OK
   - Load balance from persistence in `init`, default to 0

2. Add persistence key
   - In `PersistenceService.Keys`, add `static let currencyBalance = "app.currency.balance"`

3. Wire into `AppEnvironment`
   - Add `let currency: CurrencyService` property
   - In `init()`, create `CurrencyService(persistence: persistence)` after `persistence` init

4. Wire into SwiftUI view tree
   - In `SmartGamesApp.swift`, add `.environmentObject(env.currency)` alongside other env objects

5. Create analytics events
   - New file `AnalyticsEvent+Currency.swift` with `currencyEarned` and `currencySpent` factories

6. Hook into Sudoku level-complete
   - `SudokuGameViewModel` init: add `currencyService: CurrencyService` parameter
   - After win logic (line ~467 area, after hint grant), add:
     ```swift
     let baseReward = CurrencyReward.sudokuComplete
     let bonus = starRating >= 3 ? CurrencyReward.sudokuThreeStarBonus : 0
     let total = baseReward + bonus
     currencyService.earn(amount: total)
     analytics.log(.currencyEarned(amount: total, source: "sudoku", balanceAfter: currencyService.balance))
     ```
   - Update `SudokuModule` to pass `environment.currency` when constructing the VM

7. Hook into Drop Rush level-complete
   - `DropRushGameViewModel` init: add `currencyService: CurrencyService` parameter
   - In `handleEvent(.levelComplete(...))` (line ~116 area), after progress save:
     ```swift
     let baseReward = CurrencyReward.dropRushComplete
     let bonus = stars >= 3 ? CurrencyReward.dropRushThreeStarBonus : 0
     let total = baseReward + bonus
     currencyService.earn(amount: total)
     analytics.log(.currencyEarned(amount: total, source: "dropRush", balanceAfter: currencyService.balance))
     ```
   - Update `DropRushModule` to pass currency service when constructing game view

8. Compile and verify no errors

## Todo

- [x] Create `CurrencyService.swift` with earn/spend/persistence
- [x] Add `currencyBalance` persistence key
- [x] Wire `CurrencyService` into `AppEnvironment`
- [x] Wire `.environmentObject` into SwiftUI tree
- [x] Create `AnalyticsEvent+Currency.swift`
- [x] Hook earn into `SudokuGameViewModel` win flow
- [x] Hook earn into `DropRushGameViewModel` levelComplete flow
- [x] Update module files to pass currency service
- [x] Compile check

## Success Criteria

- `CurrencyService.balance` starts at 0 for fresh install
- Completing a Sudoku puzzle grants 15 coins (25 for 3-star)
- Completing a Drop Rush level grants 10 coins (20 for 3-star)
- Balance persists across app restarts
- `spend()` returns `false` when insufficient balance, balance unchanged
- Analytics events fire on earn/spend

## Edge Cases & Bug Risks

| Risk | Mitigation |
|------|-----------|
| Overflow at very high balance | Use `addingReportingOverflow`; clamp to `Int.max` |
| Currency goes negative | `spend()` checks `amount > balance` before deduction |
| Duplicate reward for same completion | Not an issue -- rewards are per-event, not per-level-ID. Replaying a level earns again (intended) |
| Balance lost on reinstall | UserDefaults cleared -- graceful: starts at 0, themes fall back to free |
| Thread safety | `@MainActor` ensures single-threaded access |

## Security / Persistence

- Balance stored in UserDefaults (sandboxed). No server-side validation needed for MVP.
- No encryption needed -- in-game-only currency, not real money.
- Future: if currency becomes IAP-purchasable, add receipt validation.
