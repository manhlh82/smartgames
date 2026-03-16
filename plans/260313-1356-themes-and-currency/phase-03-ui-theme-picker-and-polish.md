# Phase 3: UI Theme Picker & Polish

## Context Links

- [Plan overview](plan.md)
- [Phase 2: Theme Catalog](phase-02-theme-catalog-and-unlock.md)
- [ThemePickerView](../../SmartGames/SharedServices/Settings/ThemePickerView.swift)
- [SettingsView](../../SmartGames/SharedServices/Settings/SettingsView.swift)

## Overview

- **Priority:** P1
- **Status:** completed
- **Description:** Update theme picker UI with lock/unlock states, prices, balance display, purchase confirmation, insufficient-funds feedback. Polish and final integration.

## Key Insights

- `ThemePickerView` already iterates `BoardThemeName.allCases` with swatch previews. Extend, don't rewrite.
- Current picker is a horizontal `HStack` -- with 9 themes, switch to `LazyVGrid` (2 columns) or scrollable horizontal with larger swatches.
- Balance display should be visible in the picker section header so users know how much they have.
- Confirmation alert before purchase prevents accidental taps.

## Architecture

### Updated ThemePickerView

```
ThemePickerView
├── Section header: "Themes" + coin balance (e.g., "42 coins")
├── LazyVGrid (2 columns, spacing: 12)
│   ├── ThemeSwatchView (per theme)
│   │   ├── Mini board preview (existing)
│   │   ├── Theme name label
│   │   ├── If locked: lock icon + price badge
│   │   ├── If unlocked + selected: checkmark
│   │   └── If unlocked + not selected: no overlay
│   └── ...
└── Purchase confirmation alert
    ├── "Buy [Theme] for [X] coins?"
    ├── Confirm -> purchase() -> select if success
    └── Cancel
```

### Insufficient Funds Feedback

- If user taps locked theme and balance < price: show alert "Not enough coins! You need X more coins."
- No navigation to "earn more" screen for MVP -- just informational.

### Balance Display Component

```swift
struct CoinBalanceView: View {
    @EnvironmentObject var currency: CurrencyService
    // Shows coin icon + balance, e.g., "coin_icon 42"
}
```

Small reusable component. Place in `SmartGames/Common/UI/CoinBalanceView.swift`. Usable in picker header and potentially win screens later.

### Win Screen Reward Toast

On level-complete screens (Sudoku `SudokuWinView`, Drop Rush result overlay), show a brief "+X coins" animated label so players see their reward.

## Related Code Files

### Modify

| File | Change |
|------|--------|
| `SmartGames/SharedServices/Settings/ThemePickerView.swift` | Rewrite: grid layout, lock icons, price badges, purchase flow, balance header |
| `SmartGames/Games/Sudoku/Views/SudokuWinView.swift` | Add "+X coins" reward toast |
| `SmartGames/Games/DropRush/Views/DropRushResultOverlay.swift` | Add "+X coins" reward toast |

### Create

| File | Purpose |
|------|---------|
| `SmartGames/Common/UI/CoinBalanceView.swift` | Reusable coin balance display |
| `SmartGames/Common/UI/CoinRewardToast.swift` | Animated "+X coins" label for win screens |

## Implementation Steps

1. **Create `CoinBalanceView`**
   - `@EnvironmentObject var currency: CurrencyService`
   - HStack: SF Symbol `"dollarsign.circle.fill"` (or custom coin icon) + `Text("\(currency.balance)")`
   - Compact style, `.font(.appSubheadline)`, gold/yellow tint

2. **Create `CoinRewardToast`**
   - Takes `amount: Int` as parameter
   - Shows "+X" with coin icon, fades in with scale animation, auto-dismisses after 2s
   - Use `.transition(.scale.combined(with: .opacity))`

3. **Rewrite `ThemePickerView`**
   - Add `@EnvironmentObject var currency: CurrencyService` and `@EnvironmentObject var themeService: ThemeService`
   - Section header: HStack of "Themes" title + `CoinBalanceView()`
   - Replace `HStack` with `LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12)`
   - For each `BoardThemeName.allCases`:
     - Show `ThemeSwatchView` (reuse existing mini board)
     - Below swatch: theme name
     - If `themeService.isUnlocked(name)`:
       - If selected: checkmark overlay (existing)
       - Tap: `themeService.setTheme(name)`
     - If locked:
       - Dim overlay + lock icon + price label (e.g., "50")
       - Tap: set `@State var pendingPurchase: BoardThemeName?`
   - Alert triggered by `pendingPurchase`:
     - If `currency.balance >= theme.price`: "Buy [name] for [price] coins?" + Confirm/Cancel
     - If insufficient: "Not enough coins. You need [deficit] more coins to unlock [name]." + OK
   - On confirm: `let success = themeService.purchase(pendingPurchase!)` -> if success, auto-select

4. **Update `ThemeSwatchView`**
   - Add `isLocked: Bool` and `price: Int` parameters
   - When locked: overlay with `Color.black.opacity(0.4)` + centered lock icon + price badge at bottom
   - Border color: locked = gray, unlocked+selected = accent, unlocked = light gray

5. **Add reward toast to Sudoku win screen**
   - `SudokuWinView`: accept `coinsEarned: Int` parameter
   - Show `CoinRewardToast(amount: coinsEarned)` with delay after win animation
   - `SudokuGameViewModel`: expose `coinsEarnedOnWin: Int` computed from reward logic

6. **Add reward toast to Drop Rush result overlay**
   - `DropRushResultOverlay`: accept `coinsEarned: Int` parameter
   - Show toast on level-complete phase only (not game-over)
   - `DropRushGameViewModel`: expose `coinsEarnedOnWin: Int`

7. **Accessibility**
   - Lock state: `.accessibilityLabel("[Theme] - Locked, [price] coins")`
   - Balance: `.accessibilityLabel("[balance] coins available")`
   - Purchase result: post `.announcement` accessibility notification

8. **Compile, visual QA, polish**

## Todo

- [x] Create `CoinBalanceView.swift`
- [x] Create `CoinRewardToast.swift`
- [x] Rewrite `ThemePickerView` with grid, lock states, purchase flow
- [x] Update `ThemeSwatchView` with locked overlay
- [x] Add purchase confirmation/insufficient-funds alerts
- [x] Add coins reward toast to `SudokuWinView`
- [x] Add coins reward toast to `DropRushResultOverlay`
- [x] Expose `coinsEarnedOnWin` in both VMs
- [x] Add accessibility labels
- [x] Compile and visual QA

## Success Criteria

- All 9 themes visible in picker with correct previews
- Free themes: no lock, selectable immediately
- Locked themes: dimmed with lock icon and price
- Tapping locked theme shows purchase confirmation (or insufficient-funds message)
- Successful purchase: coins deducted, theme unlocked, auto-selected
- Win screens show "+X coins" animated toast
- Balance updates reactively (SwiftUI binding via `@Published`)

## Edge Cases & Bug Risks

| Risk | Mitigation |
|------|-----------|
| User taps purchase twice rapidly | `purchase()` is idempotent -- second call returns false (already unlocked) |
| Balance changes between alert show and confirm | Re-check in confirm handler via `currencyService.spend()` |
| 9 themes don't fit horizontally | Using grid layout (2 columns) instead of HStack |
| CoinRewardToast overlaps other UI | Position at top of win view with `ZStack` alignment |
| Accessibility: lock state not announced | Explicit `.accessibilityLabel` on each swatch |

## Security / Persistence

- Purchase flow is local-only (no server). No receipt validation needed.
- Alert confirmation prevents accidental purchases.
- All state changes go through `CurrencyService.spend()` which is atomic (single-threaded via `@MainActor`).
