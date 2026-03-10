# SmartGames

iOS multi-game hub. V1: Sudoku. Architecture supports adding more games.

## Stack

Swift 5.9 / SwiftUI / iOS 16+ · MVVM · AdMob · Firebase Analytics · UserDefaults

## Setup

```bash
brew install xcodegen
xcodegen generate
open SmartGames.xcodeproj
```

## Structure

```
SmartGames/
├── Hub/              Game hub screen
├── Games/Sudoku/     Sudoku module (Engine / ViewModels / Views)
├── SharedServices/   Ads, Analytics, Persistence, Settings, Sound
├── Navigation/       AppRouter + AppRoutes
└── Common/           UI tokens, components
```

## Adding a New Game

1. Create `Games/{Name}/` module
2. Add `GameEntry` to `HubViewModel.games`
3. Add route to `AppRoute` enum

## Docs

- `docs/admob-integration-guide.md` — activate real AdMob
- `docs/firebase-analytics-guide.md` — activate Firebase
- `docs/codebase-summary.md` — architecture reference
