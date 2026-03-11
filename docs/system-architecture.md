# System Architecture

## Overview

SmartGames is a **multi-game platform** using a modular, extensible architecture. Games are registered as `GameModule` implementations, allowing new games to be added without modifying core app logic.

**Core Pattern:** MVVM + SwiftUI + EnvironmentObject injection.

## High-Level Architecture

```
┌─────────────────────────────────────────────┐
│  SmartGamesApp (Entry, ATT, Env Setup)      │
├─────────────────────────────────────────────┤
│  AppEnvironment                             │
│  ├─ Shared Services (9 services)            │
│  ├─ GameRegistry                            │
│  └─ → registers all GameModules             │
├─────────────────────────────────────────────┤
│  ContentView (Routes via AppRoute enum)     │
│  ├─ Hub → HubView (reads GameRegistry)      │
│  ├─ Game Lobby → GameModule.makeLobbyView() │
│  └─ Game Play → GameModule.navigationDestination() │
└─────────────────────────────────────────────┘
```

## Dependency Graph

### Import Rules (Strictly Enforced)

```
SharedUI, SharedServices
    ↑
    │ (imports)
    │
Core (GameModule, GameRegistry)
    ↑
    │ (imports)
    │
Games/* (Sudoku, etc.)  ← each game independent
    ↑
    │ (imports)
    │
App/ (SmartGamesApp, ContentView, HubView)
```

**Key Rules:**
- **Engine files**: Zero UIKit/SwiftUI imports. Pure game logic.
- **Game-specific services**: Owned by GameModule, not in AppEnvironment
- **Shared services**: Only truly cross-game features in AppEnvironment
- **No game-to-game imports**: Games never import each other

## AppEnvironment (Shared Services)

Central dependency injection container. Wired at app launch.

| Service | Responsibility | Owned By |
|---------|-----------------|----------|
| `PersistenceService` | UserDefaults + JSON codec | AppEnvironment |
| `SettingsService` | App settings (sound, haptics toggle) | AppEnvironment |
| `SoundService` | AVAudioPlayer (settings-gated) | AppEnvironment |
| `HapticsService` | UIFeedbackGenerator (settings-gated) | AppEnvironment |
| `AnalyticsService` | Event logging (os.log) | AppEnvironment |
| `AdsService` | AdMob rewarded + interstitial | AppEnvironment |
| `DailyChallengeService` | Daily puzzle feature (cross-game) | AppEnvironment |
| `GameCenterService` | GKLocalPlayer auth + leaderboards | AppEnvironment |
| `StoreService` | StoreKit 2, IAP (Remove Ads, Hint Pack) | AppEnvironment |
| `GameRegistry` | Game module registry & lookup | AppEnvironment |

## GameModule Protocol

Every game implements this contract:

```swift
@MainActor
protocol GameModule: AnyObject {
    var id: String { get }                                          // e.g., "sudoku"
    var displayName: String { get }                                 // e.g., "Sudoku"
    var iconName: String { get }                                    // SF Symbol or asset
    var isAvailable: Bool { get }                                   // false = "Coming Soon"
    func makeLobbyView(environment: AppEnvironment) -> AnyView      // Lobby/menu view
    func navigationDestination(for route: AppRoute, environment: AppEnvironment) -> AnyView?  // Game play view
}
```

**Purpose:** Decouples app shell from game implementations. New games require only a new `GameModule` conformance.

## GameRegistry

Holds all registered game modules. Populated at app launch.

```swift
@MainActor
final class GameRegistry: ObservableObject {
    private(set) var modules: [String: any GameModule] = [:]

    func register(_ module: some GameModule)
    func module(for gameId: String) -> (any GameModule)?
    var allGames: [any GameModule] { ... }  // sorted
}
```

Injected as `@EnvironmentObject` in views. HubView reads `registry.allGames` to render game cards dynamically.

## Routing Architecture

### AppRoute Enum

Generic game-agnostic routes:

```swift
enum AppRoute: Hashable {
    case gameLobby(gameId: String)              // Lobby/entry for a game
    case gamePlay(gameId: String, context: GamePlayContext)
    case settings
}
```

**No hardcoded Sudoku routes.** ContentView dispatches to appropriate GameModule via `registry.navigationDestination(for:)`.

### Navigation Flow

```
ContentView
├─ route == .gameLobby(gameId)
│  └─ GameRegistry.module(gameId)?.makeLobbyView()
├─ route == .gamePlay(gameId, context)
│  └─ GameRegistry.module(gameId)?.navigationDestination(for:)
└─ route == .settings
   └─ SettingsView
```

## Sudoku Game Module (Example Implementation)

Demonstrates how a game conforms to `GameModule`.

### Structure

```
Games/Sudoku/
├── SudokuGameModule.swift          (GameModule conformance)
├── Engine/                         (pure logic, no UIKit/SwiftUI)
│   ├── SudokuGenerator.swift
│   ├── SudokuSolver.swift
│   ├── SudokuValidator.swift
│   ├── PuzzleBank.swift
│   └── SeededRandomNumberGenerator.swift
├── Models/
├── ViewModels/
│   └── SudokuGameViewModel.swift   (5-phase state machine)
└── Views/
    ├── SudokuGameView.swift        (main play screen)
    ├── SudokuBoardView.swift
    ├── SudokuCellView.swift
    ├── SudokuStatisticsView.swift
    ├── DailyChallengeView.swift
    ├── PaywallView.swift
    └── ThemePickerView.swift
```

### Game-Specific Services (Owned by SudokuGameModule)

| Service | Responsibility |
|---------|-----------------|
| `ThemeService` | Board themes (Classic, Dark, Sepia); persisted preference |
| `StatisticsService` | Per-difficulty stats (wins, streaks, best times) |

These are **not** in AppEnvironment. They're initialized by SudokuGameModule and injected into views as needed.

### Game State Machine

```
playing ↔ paused
playing → won | lost | needsHintAd
```

Managed by `SudokuGameViewModel`.

## Persistence Strategy

### Shared Keys (PersistenceService)

```
app.settings              → SettingsData
store.adsRemoved         → Bool
store.hintPackCount      → Int
sudoku.activeGame        → SudokuGameState
sudoku.hints.remaining   → Int
sudoku.playedPuzzleIDs   → Set<String>
sudoku.stats.{difficulty}  → SudokuStats
sudoku.daily.state       → DailyChallengeState
```

Game-specific stats are persisted as `sudoku.stats.*`. Future games use their own namespace (e.g., `chess.stats.*`).

## Analytics Events

All events logged via `AnalyticsService` (os.log currently; Firebase integration ready).

**Format:** snake_case event names, dot-namespaced params.

**Event Factories:**
- `AnalyticsEvent+Sudoku.swift` — Sudoku gameplay events
- `AnalyticsEvent+App.swift` — App-level events (app_launch, settings_changed)

Example:
```
sudoku_game_started(difficulty: "easy", mode: "classic")
sudoku_move_made(cell: "A1", candidate_mode: false)
sudoku_hint_requested(remaining_hints: 2)
sudoku_game_won(duration_seconds: 300, difficulty: "medium")
```

## Dependency Injection Flow

### 1. App Launch

```
SmartGamesApp.init()
├─ create AppEnvironment()
│  ├─ initialize 9 shared services
│  ├─ create GameRegistry
│  ├─ create SudokuGameModule (passes PersistenceService)
│  └─ registry.register(sudoku)
└─ @StateObject var env = AppEnvironment()
```

### 2. View Tree

```
SmartGamesApp (@StateObject env)
├─ .environmentObject(env)
├─ .environmentObject(env.gameRegistry)
├─ ContentView
│  ├─ @EnvironmentObject var registry: GameRegistry
│  └─ @EnvironmentObject var env: AppEnvironment
└─ ... (all child views can access env, registry, and game-specific services)
```

### 3. Game-Specific Service Injection

**In SudokuGameModule.makeLobbyView():**

```swift
let themeService = ThemeService(persistence: environment.persistence)
let statsService = StatisticsService(persistence: environment.persistence)
return AnyView(SudokuLobbyView()
    .environmentObject(themeService)
    .environmentObject(statsService)
)
```

Views receive game-specific services via `@EnvironmentObject`.

## Adding a New Game

1. Create `Games/{NewGame}/` with `GameModule` conformance
2. Implement `id`, `displayName`, `iconName`, `isAvailable`
3. Create game-specific services (if needed)
4. Implement `makeLobbyView()` and `navigationDestination()`
5. In `AppEnvironment.init()`:
   ```swift
   let newGame = NewGameModule(...)
   registry.register(newGame)
   ```
6. No other changes needed — HubView auto-discovers via GameRegistry

## Testing Strategy

- **Engine**: Pure unit tests (no mocks)
- **ViewModels**: @MainActor, dependency-injected for testability
- **Views**: SwiftUI preview + integration tests
- **Services**: Mock versions for unit tests

## Performance Considerations

- GameRegistry lookups: O(1) dictionary access
- View creation: Lazy navigation (only visible game views loaded)
- Persistence: Async writes via PersistenceService (non-blocking)
- Analytics: Fire-and-forget logging (no waiting)

## Security

- **IAP**: Verified via StoreKit 2 `Transaction.currentEntitlements` (source of truth)
- **Persistence**: UserDefaults is sandboxed per app
- **Analytics**: No PII logged (only gameplay metrics)
- **ATT**: Requested on app launch (if needed for IDFA)

## Version History

- **Phase 1:** Single-game (Sudoku) scaffold, services, hub, gameplay
- **Phase 2:** Analytics, ads, retention features (daily challenges, statistics)
- **Phase 2.5:** Modular architecture refactor — GameModule protocol, GameRegistry, service decoupling
- **Phase 3+:** New games, monetization improvements, content expansion
