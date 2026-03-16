# Gold Display & Toolbar Structure Exploration

**Date:** 2026-03-13
**Codebase:** SmartGames iOS App
**Focus:** Gold/Currency Display in Toolbars, Text Truncation Issues

---

## Summary

Explored Gold balance display across Hub and game views. Found Gold is displayed via `GoldBalanceView` component in HubView toolbar only (as of commit `0251fe3`). No explicit text truncation/width constraints identified on Gold display component. Game views (Sudoku, DropRush) do not currently display Gold in navigation bar — only in win/result screens via `GoldRewardToast`.

---

## 1. Gold Balance Display Component

**File:** `/Users/manh.le/github-personal/smartgames/SmartGames/Common/UI/GoldBalanceView.swift`
- **Lines:** 1-18 (18 lines total)
- **Status:** Newly created (commit `0251fe3` - Mar 13 20:17)

### Component Structure:
```swift
struct GoldBalanceView: View {
    @EnvironmentObject var gold: GoldService
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.yellow)
            Text("\(gold.balance)")
                .font(.appHeadline)                    // Font: 18pt, semibold
                .foregroundColor(.appTextPrimary)
        }
        .accessibilityLabel("\(gold.balance) Gold")
    }
}
```

### Key Details:
- **Icon:** System `dollarsign.circle.fill` (yellow)
- **Text:** Formatted as `\(gold.balance)` — direct Int interpolation
- **Font:** `.appHeadline` = 18pt semibold (defined in `AppFonts.swift`)
- **Spacing:** 4pt gap between icon and text
- **NO explicit constraints:** No `.lineLimit`, `.truncationMode`, `.frame(maxWidth:)` applied

---

## 2. Toolbar Structure Across Views

### 2.1 HubView (Main Hub Screen)
**File:** `/Users/manh.le/github-personal/smartgames/SmartGames/Hub/HubView.swift`
- **Lines:** 29-45

**Toolbar Configuration:**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        GoldBalanceView()                             // ← Gold balance ONLY in Hub
    }
    ToolbarItem(placement: .navigationBarTrailing) {
        Button { /* settings */ }                     // Settings gear icon
    }
}
```

**Navigation Title:** "SmartGames" (large display mode)
**Gold Display:** ✅ Present | Leading position

---

### 2.2 SudokuGameView (Active Gameplay)
**File:** `/Users/manh.le/github-personal/smartgames/SmartGames/Games/Sudoku/Views/SudokuGameView.swift`
- **Lines:** 178-202 (gameToolbar)

**Toolbar Configuration:**
```swift
@ToolbarContentBuilder
private var gameToolbar: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
        Button { /* back */ }                        // Back chevron
    }
    ToolbarItem(placement: .navigationBarTrailing) {
        Button { /* pause/resume */ }                // Play/pause icon
    }
}
```

**Navigation Title:** None (no toolbar item for title)
**Gold Display:** ❌ Not present during gameplay
**Note:** Gold displayed on win screen via `GoldRewardToast` (lines 225, in overlay)

---

### 2.3 SudokuLobbyView (Difficulty Selection)
**File:** `/Users/manh.le/github-personal/smartgames/SmartGames/Games/Sudoku/Views/SudokuLobbyView.swift`
- **Lines:** 46-75 (toolbar)

**Toolbar Configuration:**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        HStack(spacing: 4) {
            if gameCenterService.isAuthenticated {
                Button { /* leaderboard */ }         // Trophy icon
            }
            Button { /* statistics */ }              // Chart icon
            Button { /* theme picker */ }            // Palette icon
        }
    }
}
```

**Navigation Title:** None (large display with title section)
**Gold Display:** ❌ Not present in lobby toolbar

---

### 2.4 DropRushLobbyView (Level Select)
**File:** `/Users/manh.le/github-personal/smartgames/SmartGames/Games/DropRush/Views/DropRushLobbyView.swift`
- **Lines:** 44-56 (toolbar)

**Toolbar Configuration:**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button { /* leaderboard */ }                 // Trophy icon
            .disabled(!gameCenter.isAuthenticated)
    }
}
```

**Navigation Title:** "Drop Rush" (inline display mode)
**Gold Display:** ❌ Not present in lobby toolbar

---

### 2.5 DropRushGameView (Active Gameplay)
**File:** `/Users/manh.le/github-personal/smartgames/SmartGames/Games/DropRush/Views/DropRushGameView.swift`
- **Lines:** 78-87 (toolbar)

**Toolbar Configuration:**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button { /* quit */ }                        // Back chevron
    }
}
```

**Navigation Title:** "Level \(levelNumber)" (inline)
**Gold Display:** ❌ Not present during gameplay
**Note:** Gold displayed on result overlay via `GoldRewardToast` (line 175)

---

## 3. GoldService Architecture

**File:** `/Users/manh.le/github-personal/smartgames/SmartGames/SharedServices/Gold/GoldService.swift`
- **Lines:** 1-64 (64 lines total)

### Balance Management:
- **Type:** `Int` (@Published property)
- **Initial Value:** 0 (or migrated from legacy key)
- **Overflow Protection:** Capped at `Int.max / 2` (safe range)
- **Persistence Key:** `PersistenceService.Keys.goldBalance`

### Public API:
- `earn(amount: Int)` — Adds Gold with overflow safety
- `spend(amount: Int) -> Bool` — Spends if sufficient balance
- Migration support for legacy "app.currency.balance" key

---

## 4. Gold Reward Toast Component

**File:** `/Users/manh.le/github-personal/smartgames/SmartGames/Common/UI/GoldRewardToast.swift`
- **Lines:** 1-42

### Display:
```swift
HStack(spacing: 6) {
    Image(systemName: "dollarsign.circle.fill")
    Text("+\(amount) Gold")
        .font(.appHeadline)
        .fontWeight(.bold)
}
.padding(.horizontal, 16)
.padding(.vertical, 8)
.background(Color.black.opacity(0.72))
.clipShape(Capsule())
```

**Font:** .appHeadline (18pt, bold)
**Duration:** 2.2 seconds (auto-dismisses)
**Used in:** Win screens for both Sudoku & DropRush

---

## 5. Font Definition

**File:** `/Users/manh.le/github-personal/smartgames/SmartGames/Common/UI/AppFonts.swift`

```swift
extension Font {
    static let appTitle    = Font.system(size: 28, weight: .bold)
    static let appHeadline = Font.system(size: 18, weight: .semibold)  // ← Used for Gold
    static let appBody     = Font.system(size: 16, weight: .regular)
    static let appCaption  = Font.system(size: 13, weight: .regular)
    static let appMono     = Font.system(size: 16, weight: .regular, design: .monospaced)
}
```

**Gold Text Font:** `.appHeadline` = 18pt semibold
**No custom sizing or constraints** on Gold display component

---

## 6. Text Truncation & Layout Analysis

### Current Implementation:
- **GoldBalanceView:**
  - ❌ No `.lineLimit` modifier
  - ❌ No `.truncationMode` modifier
  - ❌ No `.frame(maxWidth:)` constraint
  - ❌ No `.layoutPriority` modifier
  - Uses default HStack auto-sizing

### Potential Truncation Scenarios:
1. **Large balance numbers** (e.g., 999999+) could exceed toolbar space
2. **Multiple toolbar items** (icon + text + future buttons) on narrow devices (SE, older iPhones)
3. **iPad landscape with large safe area** may have different constraints
4. **Localization** (if Gold displays as multi-word phrase) could expand width

### Current Safeguards:
- System-managed toolbar layout with flexible spacing
- Icon is fixed-width (system symbol)
- Text is direct integer display (predictable length)
- Small HStack gap (4pt) is minimal

---

## 7. Implementation Timeline

| Commit | Date | Change |
|--------|------|--------|
| `bbb7eb4` | (recent) | Rename currency → Gold (GoldService, events, persistence) |
| `0251fe3` | 2026-03-13 20:17 | **Show Gold balance in hub toolbar** (GoldBalanceView added) |

---

## 8. Code Location Reference

| Component | Path | Lines | Status |
|-----------|------|-------|--------|
| **GoldBalanceView** | `SmartGames/Common/UI/GoldBalanceView.swift` | 1-18 | ✅ New |
| **GoldService** | `SmartGames/SharedServices/Gold/GoldService.swift` | 1-64 | ✅ Core |
| **GoldRewardToast** | `SmartGames/Common/UI/GoldRewardToast.swift` | 1-42 | ✅ Display |
| **HubView** | `SmartGames/Hub/HubView.swift` | 31-34 | ✅ Toolbar |
| **SudokuGameView** | `SmartGames/Games/Sudoku/Views/SudokuGameView.swift` | 178-202 | ⚠️ No Gold display |
| **SudokuLobbyView** | `SmartGames/Games/Sudoku/Views/SudokuLobbyView.swift` | 46-75 | ⚠️ No Gold display |
| **DropRushGameView** | `SmartGames/Games/DropRush/Views/DropRushGameView.swift` | 78-87 | ⚠️ No Gold display |
| **DropRushLobbyView** | `SmartGames/Games/DropRush/Views/DropRushLobbyView.swift` | 46-56 | ⚠️ No Gold display |
| **AppFonts** | `SmartGames/Common/UI/AppFonts.swift` | 1-10 | ✅ Reference |

---

## 9. Key Findings

### ✅ Gold Display Architecture:
1. **Centralized Component:** Single `GoldBalanceView` for all Gold display
2. **Consistent Font:** 18pt semibold (appHeadline)
3. **Service-Driven:** Uses `@EnvironmentObject GoldService` for reactive updates
4. **Accessibility:** Proper labels included ("X Gold")

### ⚠️ Potential Issues:
1. **No Text Truncation Handling:** Long balances (999999) could overflow toolbar
2. **No Width Constraint:** Component grows unbounded (relies on HStack)
3. **Hub-Only Display:** Gold not visible in game lobbies or during gameplay (by design?)
4. **No Localization Fallback:** If Gold label changes, width could increase

### ❓ Design Decisions Not Clear:
1. Why Gold only in Hub toolbar, not in game lobbies?
2. Should game views show "in-game" context on game completion screen vs. updating hub counter?
3. Are large balance numbers (10000+) expected, or is there a hard cap?

---

## Recommendations

1. **Add Width Constraints:** Consider `.frame(maxWidth: 120)` or similar to `GoldBalanceView`
2. **Test Large Balances:** Validate 5-6 digit numbers render correctly in toolbar
3. **Consider Game Lobby Display:** May want Gold visible in Sudoku/DropRush lobbies too
4. **Add Truncation Fallback:** `.lineLimit(1).truncationMode(.tail)` if width exceeded
5. **iPad Testing:** Verify layout on landscape/larger screens

---

## Unresolved Questions

1. **Intended Balance Cap?** Is `Int.max / 2` the final ceiling, or should there be lower limit?
2. **Multi-Language Support?** How does Gold label change (e.g., "Monedas" in Spanish) affect width?
3. **Future Toolbar Items?** Any planned additions that could compete for space with Gold display?
4. **Game View Gold Display:** Is intentional absence from game lobbies/gameplay planned, or oversight?

