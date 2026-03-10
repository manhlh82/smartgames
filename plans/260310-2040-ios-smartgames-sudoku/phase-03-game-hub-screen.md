# Phase 03 — Game Hub Screen

**Priority:** High | **Effort:** S | **PR:** PR-03

---

## Overview

The central launcher screen users see on app open. Shows all available games as cards. V1 ships with Sudoku only; remaining slots show as "Coming Soon" or are hidden. Gear icon opens Settings.

Reference: Screenshot 1 — light grey background, white rounded cards, game icon (circle), game name, blue play button (▶).

---

## PR-03 Goal

Implement HubView with game card list, navigation to Sudoku lobby, Settings sheet, Privacy Policy / Terms links.

---

## Screen Spec

```
┌─────────────────────────────────┐
│ SmartGames          [⚙]         │  ← nav title + settings gear
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐  │
│  │ [icon]  Sudoku      [▶]  │  │  ← GameCardView
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ [icon]  Coming Soon  [▶]  │  │  ← disabled card (future games)
│  └───────────────────────────┘  │
│                                 │
│  Privacy Policy   Terms of Use  │  ← footer links
└─────────────────────────────────┘
```

---

## Data Model

```swift
// GameEntry.swift
struct GameEntry: Identifiable {
    let id: String
    let displayName: String
    let iconAsset: String      // Asset catalog name
    let isAvailable: Bool      // false → greyed out / "Coming Soon"
    let makeDestination: () -> AnyView
}
```

Game registry (static list in HubViewModel):

```swift
// HubViewModel.swift
final class HubViewModel: ObservableObject {
    let games: [GameEntry] = [
        GameEntry(
            id: "sudoku",
            displayName: "Sudoku",
            iconAsset: "icon-sudoku",
            isAvailable: true,
            makeDestination: { AnyView(SudokuLobbyView()) }
        )
        // Future: ParkingJam, MergePuzzle, BlockPuzzle
    ]
}
```

---

## GameCardView

```
┌──────────────────────────────────────────┐
│  ○ [icon 60pt]   Game Name    [▶ blue]   │
└──────────────────────────────────────────┘
```

- White card, corner radius 16, shadow (opacity 0.08, radius 8)
- Icon: circular image, 60pt
- Name: system font, semibold, 18pt
- Play button: blue (#007AFF), rounded square, SF Symbol `play.fill`
- Disabled state: 50% opacity, no tap action, subtitle "Coming Soon"
- Tap entire card OR play button → navigate to game lobby

---

## Navigation

```swift
// AppRouter.swift
enum AppRoute: Hashable {
    case sudokuLobby
    case sudokuGame(difficulty: SudokuDifficulty)
    case settings
}

// Root NavigationStack with path binding
NavigationStack(path: $router.path) {
    HubView()
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .sudokuLobby: SudokuLobbyView()
            case .sudokuGame(let diff): SudokuGameView(difficulty: diff)
            case .settings: SettingsView()
            }
        }
}
```

---

## App Icon & Branding

- App name: **SmartGames** (interim — pending App Store name check)
- Color palette:
  - Accent blue: `#007AFF` (iOS system blue)
  - Background: `#F2F2F7` (iOS system grouped background)
  - Card: `.white`
  - Text primary: `#1C1C1E`
  - Text secondary: `#8E8E93`

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `Hub/HubView.swift` | Create |
| `Hub/HubViewModel.swift` | Create |
| `Hub/Models/GameEntry.swift` | Create |
| `Navigation/AppRouter.swift` | Create |
| `Navigation/AppRoutes.swift` | Create |
| `Common/Components/GameCardView.swift` | Create |
| `Common/UI/AppColors.swift` | Create |
| `Common/UI/AppTheme.swift` | Create |
| `Resources/Assets.xcassets` | Add game icons |

---

## Acceptance Criteria

- [ ] Hub screen renders with at least Sudoku card
- [ ] Tap Sudoku card → navigates to SudokuLobbyView (can be empty placeholder)
- [ ] Settings gear → presents SettingsView sheet
- [ ] Privacy Policy / Terms links open Safari
- [ ] Coming Soon cards are visually distinct and non-tappable

---

## Tests Needed

- `HubViewModelTests` — games list not empty, sudoku isAvailable == true
- Snapshot test for GameCardView (normal + disabled states)

---

## Dependencies

- PR-01 (project structure)
- PR-02 (SettingsService for gear icon)
