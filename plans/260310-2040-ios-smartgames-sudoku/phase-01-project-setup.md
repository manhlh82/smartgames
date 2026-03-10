# Phase 01 — Project Setup & Architecture Scaffold

**Priority:** Critical | **Effort:** S | **PR:** PR-01

---

## Overview

Bootstrap the Xcode project with the multi-game module architecture. No game logic yet — just structure, navigation skeleton, and CI.

---

## PR-01 Goal

Create Xcode project with folder structure, SwiftUI app entry point, NavigationStack skeleton, and GitHub Actions CI.

---

## Folder / Module Structure

```
SmartGames/
├── SmartGamesApp.swift               # App entry point
├── AppEnvironment.swift              # Environment objects injection
├── Navigation/
│   ├── AppRouter.swift               # Root navigation state
│   └── AppRoutes.swift               # Route enum
│
├── Hub/                              # Game hub / launcher
│   ├── HubView.swift
│   ├── HubViewModel.swift
│   └── Models/
│       └── GameEntry.swift           # Game metadata model
│
├── Games/
│   └── Sudoku/                       # Sudoku feature module
│       ├── SudokuModule.swift        # Module registration
│       ├── Engine/                   # Pure logic, no UI
│       │   ├── SudokuPuzzle.swift
│       │   ├── SudokuGenerator.swift
│       │   ├── SudokuSolver.swift
│       │   └── SudokuValidator.swift
│       ├── Models/
│       │   ├── SudokuGameState.swift
│       │   ├── SudokuCell.swift
│       │   └── SudokuDifficulty.swift
│       ├── ViewModels/
│       │   ├── SudokuGameViewModel.swift
│       │   └── SudokuLobbyViewModel.swift
│       └── Views/
│           ├── SudokuLobbyView.swift
│           ├── SudokuGameView.swift
│           ├── SudokuBoardView.swift
│           ├── SudokuCellView.swift
│           ├── SudokuNumberPadView.swift
│           ├── SudokuToolbarView.swift
│           └── SudokuWinView.swift
│
├── SharedServices/
│   ├── Persistence/
│   │   ├── PersistenceService.swift
│   │   └── Models/                   # Codable game state models
│   ├── Ads/
│   │   ├── AdsService.swift
│   │   ├── RewardedAdCoordinator.swift
│   │   └── InterstitialAdCoordinator.swift
│   ├── Analytics/
│   │   └── AnalyticsService.swift
│   ├── Settings/
│   │   ├── SettingsService.swift
│   │   └── SettingsView.swift
│   └── Sound/
│       ├── SoundService.swift
│       └── HapticsService.swift
│
├── Common/
│   ├── UI/
│   │   ├── AppColors.swift
│   │   ├── AppFonts.swift
│   │   └── AppTheme.swift
│   ├── Extensions/
│   │   └── Color+Hex.swift
│   └── Components/
│       ├── PrimaryButton.swift
│       └── GameCardView.swift         # Reusable game card for hub
│
└── Resources/
    ├── Assets.xcassets
    ├── Sudoku/
    │   └── puzzles.json               # Pre-generated puzzle bank
    └── Sounds/
        ├── tap.caf
        ├── error.caf
        └── win.caf
```

---

## Architecture Pattern

**MVVM + Environment Objects**

```
View ←→ ViewModel (ObservableObject) ←→ Services (Singletons/EnvironmentObjects)
```

- `@StateObject` for ViewModels owned by views
- `@EnvironmentObject` for shared services (AdsService, AnalyticsService, SettingsService, SoundService)
- `@Observable` (iOS 17 macro) or `ObservableObject` (iOS 16 compat) for ViewModels
- Navigation: `NavigationStack` + `NavigationPath` at root

**Game Module Protocol:**

```swift
protocol GameModule {
    static var id: String { get }
    static var displayName: String { get }
    static var icon: String { get }  // SF Symbol or asset name
    static func makeLobbyView() -> AnyView
}
```

Each game registers itself. The hub reads registered modules to build its list.

---

## Files to Create

| File | Purpose |
|------|---------|
| `SmartGames.xcodeproj` | Xcode project |
| `SmartGamesApp.swift` | App entry, environment injection |
| `AppEnvironment.swift` | All shared services as `@EnvironmentObject` |
| `Navigation/AppRouter.swift` | NavigationPath + route enum |
| `Common/UI/AppColors.swift` | Color palette (blue accent, light bg) |
| `Common/UI/AppFonts.swift` | Font scale definitions |
| `.github/workflows/ci.yml` | Build + test on push |
| `Podfile` or `Package.swift` | Google AdMob SPM/CocoaPods dep |

---

## Acceptance Criteria

- [ ] Project builds cleanly on Xcode 15+
- [ ] Empty hub screen renders with NavigationStack
- [ ] Folder structure matches spec
- [ ] CI workflow runs on push to `main` and PRs
- [ ] AdMob dependency added (test IDs only)

---

## Tests Needed

- None for this PR (structure only)
- CI should at least run `xcodebuild build`

---

## Dependencies

None — first PR.
