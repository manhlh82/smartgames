# Phase 05 — UI Updates

**Priority:** High
**Status:** Completed
**Depends on:** Phase 01 (DiamondService), Phase 02 (gold updates), Phase 04 (StoreView)

## Overview
Update shared UI components: persistent top bar with diamond (bright) + gold (subdued), redesigned death popup with two-column CTA, store tabs with premium badges, and cosmetic rarity visual indicators.

## Related Code Files
- **Modify:** `SmartGames/SharedComponents/GoldBalanceView.swift` — extend to show both currencies
- **Create:** `SmartGames/SharedComponents/CurrencyBarView.swift` — combined top bar (diamond + gold)
- **Modify:** `SmartGames/Games/DropRush/Views/DropRushResultOverlay.swift` — two-column death CTA
- **Modify:** `SmartGames/Games/Stack2048/Views/Stack2048GameOverOverlay.swift` — two-column death CTA
- **Modify:** `SmartGames/Games/Sudoku/Views/SudokuGameView.swift` — embed CurrencyBarView in toolbar
- **Modify:** `SmartGames/Games/DropRush/Views/DropRushGameView.swift` — embed CurrencyBarView
- **Modify:** `SmartGames/Games/Stack2048/Views/Stack2048GameView.swift` — embed CurrencyBarView
- **Create:** `SmartGames/SharedComponents/DeathPopupView.swift` — reusable two-column continue popup
- **Modify:** `SmartGames/SharedServices/Store/StoreView.swift` (Phase 04) — add "Exclusive" badges, rarity indicators

## CurrencyBarView
```swift
// Persistent top bar — diamond count prominent, gold subdued
struct CurrencyBarView: View {
    @EnvironmentObject var goldService: GoldService
    @EnvironmentObject var diamondService: DiamondService

    var body: some View {
        HStack(spacing: 12) {
            // Diamond — bright, prominent
            Label("\(diamondService.balance)", systemImage: "diamond.fill")
                .foregroundStyle(.cyan)
                .fontWeight(.bold)

            // Gold — subdued
            Label("\(goldService.balance)", systemImage: "circle.fill")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}
```
- Replace existing `GoldBalanceView` usages in game toolbars with `CurrencyBarView`
- Keep `GoldBalanceView` for result overlays (shows amount earned, not balance)

## DeathPopupView (two-column CTA)
```
┌─────────────────────────────────────┐
│         Game Over                   │
│                                     │
│  ┌────────────┐  ┌────────────────┐ │
│  │  Watch Ad  │  │  ◆ 2 Diamonds  │ │  ← Right column highlighted
│  │  1 Heart   │  │  Full Restore  │ │
│  └────────────┘  └────────────────┘ │
│                                     │
│         [Quit]                      │
└─────────────────────────────────────┘
```
- Right column (diamond): accent border, brighter background, slightly larger
- If `diamondService.balance < 2`: dim diamond button, show "Not enough ◆" label + "Get Diamonds →" link to store
- Callbacks: `onWatchAd: () -> Void`, `onUseDiamonds: () -> Void`, `onQuit: () -> Void`
- Used by DropRush and Stack2048 death overlays; Sudoku uses it only if hearts system applies

## Store UI — Premium Badges & Rarity Indicators
- Premium tab title: "Premium ◆" with cyan diamond icon
- Legendary items: gold shimmer border animation (subtle)
- Rare items: silver/blue border
- Common items: no border
- "EXCLUSIVE" badge: small cyan pill overlay on item thumbnail
- Piggy bank row: horizontal progress bar `[███░░░░] 7/10 ◆` with unlock button
- Limited-time bundles: small countdown timer label (hours:minutes) below bundle card

## Top Bar Layout (per game)
```
[←Back]  [CurrencyBarView: ◆5  🪙 1,240]  [⚙️]
```
- Diamond always left of gold in bar
- Both values animate (CountingLabel style) when earned

## Implementation Steps
1. Create `CurrencyBarView.swift` with diamond (bright/cyan) + gold (subdued) display
2. Replace `GoldBalanceView` in toolbar usages with `CurrencyBarView` across all 3 games
3. Create `DeathPopupView.swift` — reusable, callback-based, two-column layout
4. Update `DropRushResultOverlay` — use `DeathPopupView` for game-over state
5. Update `Stack2048GameOverOverlay` — use `DeathPopupView`
6. Add "Not enough diamonds" state + store deep-link in `DeathPopupView`
7. Update `StoreView` (Phase 04) — add rarity borders, "EXCLUSIVE" badge, piggy bank progress bar
8. Add countdown timer display for limited-time bundles (timer data from `StarterPackService` or bundle model)
9. Animate currency values on earn (match existing `GoldRewardToast` style)
10. Verify `CurrencyBarView` updates reactively when diamonds/gold change

## Todo
- [ ] Create `CurrencyBarView.swift`
- [ ] Replace GoldBalanceView in toolbars (Sudoku, DropRush, Stack2048)
- [ ] Create `DeathPopupView.swift` (two-column, callback-based)
- [ ] Update DropRush result overlay to use DeathPopupView
- [ ] Update Stack2048 game over overlay to use DeathPopupView
- [ ] Add insufficient-diamonds state + store link in DeathPopupView
- [ ] Add rarity borders + EXCLUSIVE badge to StoreView items
- [ ] Add piggy bank progress bar row in store
- [ ] Add bundle countdown timer label
- [ ] Accessibility: VoiceOver labels for diamond/gold counts

## Success Criteria
- Top bar shows ◆ N (cyan, bold) and 🪙 N (subdued) in all game views
- Death popup two-column: right (diamond) visually highlighted; dims if balance < 2
- Store premium tab shows rarity borders and exclusive badges correctly
- Piggy bank progress bar reflects live fractional value
- All currency count animations are smooth and don't cause layout jumps
