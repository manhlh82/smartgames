# Codebase Summary

## Architecture

MVVM + EnvironmentObject. All services injected at root via `AppEnvironment`.

## Key Files

| File | Purpose |
|------|---------|
| `SmartGamesApp.swift` | App entry, env injection, ATT |
| `AppEnvironment.swift` | Central DI container |
| `Navigation/AppRouter.swift` | NavigationPath router |
| `Hub/HubViewModel.swift` | Game registry |

## Sudoku Module

| File | Purpose |
|------|---------|
| `Engine/SudokuGenerator.swift` | Random backtracking generation |
| `Engine/SudokuSolver.swift` | MRV solver + uniqueness check |
| `Engine/SudokuValidator.swift` | Move validation, hint, win check |
| `Engine/PuzzleBank.swift` | JSON puzzle pool + played tracking |
| `ViewModels/SudokuGameViewModel.swift` | 5-phase game state machine |
| `Views/SudokuGameView.swift` | Main gameplay screen |
| `Views/SudokuBoardView.swift` | 9x9 grid + Canvas lines |
| `Views/SudokuCellView.swift` | Cell with 6 highlight states |

## Shared Services

| Service | Notes |
|---------|-------|
| `PersistenceService` | UserDefaults+JSON, Keys enum |
| `SettingsService` | Persists on change |
| `SoundService` | AVAudioPlayer, settings-gated |
| `HapticsService` | UIFeedbackGenerator, settings-gated |
| `AdsService` | Stub; see admob-integration-guide.md |
| `AnalyticsService` | os.log; see firebase-analytics-guide.md |

## Game State Machine

```
playing ↔ paused
playing → won | lost | needsHintAd
```

## Persistence Keys

- `sudoku.activeGame` — SudokuGameState
- `sudoku.hints.remaining` — Int
- `sudoku.playedPuzzleIDs` — Set<String>
- `sudoku.stats.{difficulty}` — SudokuStats
- `app.settings` — SettingsData

## PR History

01 scaffold · 02 services · 03 hub · 04 engine · 05-07 gameplay · 08 ads · 09 analytics · 10 polish
