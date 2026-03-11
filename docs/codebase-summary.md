# Codebase Summary

## Architecture

MVVM + EnvironmentObject. All services injected at root via `AppEnvironment`.

## Key Files

| File | Purpose |
|------|---------|
| `SmartGamesApp.swift` | App entry, env injection, ATT |
| `AppEnvironment.swift` | Central DI container; wires shared & game modules |
| `Core/GameModule.swift` | Protocol defining game module contract |
| `Core/GameRegistry.swift` | Holds all registered game modules |
| `Navigation/AppRouter.swift` | NavigationPath router |
| `Hub/HubViewModel.swift` | Reads games from GameRegistry |

## Sudoku Game Module

Registered via `SudokuGameModule` conforming to `GameModule` protocol.

**Sudoku owns:**
- `ThemeService` — Board themes (persisted via SettingsService)
- `StatisticsService` — Per-difficulty stats (persisted via PersistenceService)

| File | Purpose |
|------|---------|
| `SudokuGameModule.swift` | Implements GameModule contract; owns theme + stats services |
| `Engine/SudokuGenerator.swift` | Random/seeded backtracking generation |
| `Engine/SudokuSolver.swift` | MRV solver + uniqueness check |
| `Engine/SudokuValidator.swift` | Move validation, hint, win check |
| `Engine/PuzzleBank.swift` | JSON puzzle pool + played tracking |
| `Engine/SeededRandomNumberGenerator.swift` | xorshift64 PRNG for deterministic daily puzzles |
| `ViewModels/SudokuGameViewModel.swift` | 5-phase game state machine |
| `Views/SudokuGameView.swift` | Main gameplay screen |
| `Views/SudokuBoardView.swift` | 9x9 grid + Canvas lines |
| `Views/SudokuCellView.swift` | Cell with 6 highlight states |
| `Views/SudokuStatisticsView.swift` | Per-difficulty stats screen |
| `Views/SudokuStatsCardsGrid.swift` | Stats metric cards (win rate, streaks, times) |
| `Views/DailyChallengeView.swift` | Daily challenge play screen |
| `Views/PaywallView.swift` | IAP display (Remove Ads, Hint Pack) |
| `Views/ThemePickerView.swift` | Board theme selector with previews |

## Shared Cross-Game Services (AppEnvironment)

| Service | Purpose | Scope |
|---------|---------|-------|
| `PersistenceService` | UserDefaults+JSON, Keys enum | Shared |
| `SettingsService` | App-wide settings (persisted) | Shared |
| `SoundService` | AVAudioPlayer, settings-gated | Shared |
| `HapticsService` | UIFeedbackGenerator, settings-gated | Shared |
| `AdsService` | AdMob rewarded + interstitial | Shared |
| `AnalyticsService` | Event logging | Shared |
| `DailyChallengeService` | Cross-game daily feature | Shared |
| `GameCenterService` | GKLocalPlayer auth, leaderboards | Shared |
| `StoreService` | StoreKit 2, IAP (Remove Ads, Hint Pack) | Shared |
| `GameRegistry` | Game module registration | Shared |

## Game-Specific Services (Inside GameModule)

**Sudoku** owns its own:
- `ThemeService` — Board themes (Classic/Dark/Sepia)
- `StatisticsService` — Per-difficulty stats

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
