# Phase 1: Architecture Assessment

## What's Already Good

1. **AppEnvironment DI container** -- clean centralized service creation, single injection point
2. **Games/Sudoku/ folder** -- Engine, Models, ViewModels, Views already separated
3. **SharedServices/ organization** -- each service in own subfolder, `@MainActor ObservableObject` pattern
4. **Common/UI design tokens** -- `AppColors`, `AppFonts`, `AppTheme` already extracted
5. **Engine isolation** -- Sudoku engine files have zero UIKit/SwiftUI imports
6. **SudokuModule struct exists** -- placeholder for plug-in registration (just needs protocol)
7. **GameEntry model** -- already used for hub card rendering
8. **Code standards doc** -- has "New Game Checklist" proving multi-game was anticipated

## What's Too Coupled

### Critical Coupling Points

| File | Problem | Impact |
|------|---------|--------|
| `Navigation/AppRoutes.swift` | `AppRoute` enum hardcodes `sudokuLobby`, `sudokuGame(SudokuDifficulty)`, `sudokuDailyChallenge`, `sudokuStatistics` | Adding game #2 requires modifying this enum -- violates Open/Closed |
| `ContentView.swift` | Switch on `AppRoute` builds Sudoku views directly, passes 8+ services manually | Every new game adds another case with manual service wiring |
| `ContentView.swift` | Imports `SudokuDifficulty`, `SudokuPuzzle`, `SudokuGameView`, `DailyChallengeView` | App shell depends on game internals |
| `HubViewModel.swift` | Hardcodes `GameEntry` array with `.sudokuLobby` route | New game = edit HubViewModel |
| `SmartGamesApp.swift` | Injects 11 `@EnvironmentObject`s individually | New service = touch app entry point |
| `SudokuLobbyView.swift` | Creates `PersistenceService()` in init as workaround for `@StateObject` | Breaks DI contract |

### Sudoku-Specific Services in SharedServices/

These live in `SharedServices/` but are Sudoku-only:

| Service | Why it's Sudoku-specific |
|---------|------------------------|
| `StatisticsService` | Tracks `SudokuStats` per difficulty |
| `DailyChallengeService` | Generates Sudoku daily puzzles, Sudoku-specific streak |
| `ThemeService` / `BoardTheme` | Board themes are Sudoku grid themes |
| `AnalyticsEvent+Sudoku.swift` | Sudoku event factories |

**Keep in SharedServices:** Persistence, Settings, Sound, Haptics, Ads, Analytics (core), GameCenter, Store

### Hidden Dependencies

- `GameEntry.route` is typed as `AppRoute?` -- couples Hub to route enum
- `PersistenceService.Keys` mixes app-level and Sudoku-level keys in one enum
- `SettingsView` and `ThemePickerView` live inside `SharedServices/Settings/` but are views (belong in SharedUI or game module)

## What Will Become Painful at Game #2

1. **AppRoute explosion** -- 4 Sudoku routes exist; game #2 adds 3-4 more. Enum grows unbounded
2. **ContentView routing** -- switch statement doubles in size, imports game #2 types
3. **EnvironmentObject proliferation** -- 11 today, game #2 might add 2-3 more
4. **PersistenceService.Keys conflicts** -- namespace collision risk between games
5. **StatisticsService assumptions** -- hardcoded to SudokuStats struct
6. **Hub registration** -- manually editing HubViewModel array

## What Stays in App Target vs Moves

### Stays in App Target (thin shell)
- `SmartGamesApp.swift` -- entry point, env injection
- `AppEnvironment.swift` -- DI container (will reference game modules)
- `ContentView.swift` -- root view with NavigationStack (simplified)

### Moves to Core/
- `AppRouter.swift` -- navigation primitives
- `GameModule` protocol (new) -- game plug-in contract
- `AppRoute` -- refactored to support dynamic game routes

### Moves to FeatureGameHub/
- `HubView.swift`, `HubViewModel.swift`, `GameEntry.swift`
- `GameCardView.swift` (from Common/Components)

### Moves to Games/Sudoku/ (already mostly there)
- `StatisticsService`, `DailyChallengeService`, `ThemeService` -- move into Games/Sudoku/Services/
- `AnalyticsEvent+Sudoku.swift` -- stays with Sudoku
- `ThemePickerView.swift` -- move from SharedServices/Settings to Games/Sudoku/Views/
- `SudokuStatisticsView.swift`, `SudokuStatsCardsGrid.swift` -- already there

### Stays in SharedServices/
- Persistence, Settings, Sound, Haptics, Ads, Analytics, GameCenter, Store

### Stays in SharedUI/ (rename from Common/)
- `AppColors`, `AppFonts`, `AppTheme`, `PrimaryButton`
- `BoardTheme` moves to Games/Sudoku/ (it's Sudoku-specific)
