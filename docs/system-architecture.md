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
| `AnalyticsService` | Event logging (os.log); 14 ad/monetization events | AppEnvironment |
| `AdsService` | AdMob rewarded + interstitial coordinators | AppEnvironment |
| `BannerAdCoordinator` | Banner ad lifecycle (load, impression, failure) | AppEnvironment |
| `InterstitialAdCoordinator` | Interstitial after N levels (no session cap) | AppEnvironment |
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
    var monetizationConfig: MonetizationConfig { get }              // Per-game ad settings
    func makeLobbyView(environment: AppEnvironment) -> AnyView      // Lobby/menu view
    func navigationDestination(for route: AppRoute, environment: AppEnvironment) -> AnyView?  // Game play view
}
```

**Purpose:** Decouples app shell from game implementations. New games require only a new `GameModule` conformance. `monetizationConfig` allows per-game customization of ad frequency, hint rewards, and mistake reset features.

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

## Game Module Implementations

### Sudoku (Example 1)

Demonstrates basic game conformance to `GameModule`.

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
│   └── SudokuGameViewModel.swift   (7-phase state machine)
└── Views/
    ├── SudokuGameView.swift        (main play screen)
    ├── SudokuBoardView.swift
    ├── SudokuCellView.swift
    ├── SudokuStatisticsView.swift
    ├── DailyChallengeView.swift
    ├── PaywallView.swift
    └── ThemePickerView.swift
```

**Game-Specific Services:**
| Service | Responsibility |
|---------|-----------------|
| `ThemeService` | Board themes (Classic, Dark, Sepia); persisted preference |
| `StatisticsService` | Per-difficulty stats (wins, streaks, best times) |

**Game State Machine:**
```
playing ↔ paused
playing → won | lost | needsHintAd | needsMistakeResetAd
```

### Drop Rush (Example 2)

Extends pattern with real-time engine, haptics/SFX, and ad-prompted continue flow.

```
Games/DropRush/
├── DropRushModule.swift            (GameModule conformance)
├── Engine/                         (pure logic, no UIKit/SwiftUI)
│   ├── DropRushEngine.swift        (tick-based game loop)
│   ├── SpawnScheduler.swift        (wave-based spawning)
│   └── LevelDefinitions.swift      (30 level configs)
├── Models/
│   ├── DropRushGameState.swift
│   ├── LevelConfig.swift
│   ├── DropRushStats.swift
│   └── FallingObject.swift
├── Services/
│   └── DropRushAudioConfig.swift
├── ViewModels/
│   ├── DropRushGameViewModel.swift (6-phase state machine)
│   └── DropRushGameViewModel+Actions.swift
└── Views/
    ├── DropRushGameView.swift      (main play screen + watchingAd overlay)
    ├── DropRushLobbyView.swift
    ├── DropRushResultOverlay.swift
    ├── DropRushHUDView.swift
    ├── DropRushInputBarView.swift
    └── DropRushPauseOverlay.swift
```

**Game State Machine:**
```
countdown → playing ↔ paused
playing → watchingAd → (continue) → playing | gameOver
playing → levelComplete | gameOver
```

**New Pattern: ViewModel+Actions Extension**
- Separates state transitions from UI rendering
- `DropRushGameViewModel+Actions.swift` handles `requestContinue()` with rewarded ad flow
- Enables 1 continue per attempt (tracked in `continueUsedThisAttempt`)

## Persistence Strategy

### Shared Keys (PersistenceService)

```
app.settings                    → SettingsData
store.adsRemoved               → Bool
store.hintPackCount            → Int
sudoku.activeGame              → SudokuGameState
sudoku.hints.remaining         → Int
sudoku.playedPuzzleIDs         → Set<String>
sudoku.stats.{difficulty}      → SudokuStats
sudoku.daily.state             → DailyChallengeState
```

Game-specific stats are persisted as `sudoku.stats.*`. Future games use their own namespace (e.g., `chess.stats.*`).

### Monetization Persistence

Hint balance tracked per-game:
- `sudoku.hints.remaining` — Int, capped at `monetizationConfig.maxHintCap` (default 3)
- Rewarded ad grants +3 hints; level completion grants +1 (both capped)
- IAP hint pack (+12 hints) bypasses cap, stored in `store.hintPackCount`
- Mistake reset uses tracked per-level in `SudokuGameState.mistakeResetUsesThisLevel` (max 1 per level)

## Analytics Events

All events logged via `AnalyticsService` (os.log currently; Firebase integration ready).

**Format:** snake_case event names, dot-namespaced params.

**Event Factories:**
- `AnalyticsEvent+Sudoku.swift` — Sudoku gameplay events
- `AnalyticsEvent+Ads.swift` — 14 monetization events (new in Phase 2.5)
- `AnalyticsEvent+App.swift` — App-level events (app_launch, settings_changed)

**Monetization Events (14 new):**
- Banner: `ad_banner_loaded`, `ad_banner_load_failed`, `ad_banner_clicked`, `ad_banner_impression`
- Interstitial: `ad_interstitial_shown`, `ad_interstitial_dismissed`, `ad_interstitial_skipped`
- Hints: `hint_requested`, `hint_granted_from_ad`, `hint_granted_from_level_complete`
- Mistake Reset: `mistake_reset_prompt_shown`, `mistake_reset_used`, `mistake_reset_declined`
- Unavailable: `ad_unavailable` (load failures, no fill)

Example:
```
sudoku_game_started(difficulty: "easy", mode: "classic")
sudoku_move_made(cell: "A1", candidate_mode: false)
hint_requested(remaining_hints: 2)
sudoku_game_won(duration_seconds: 300, difficulty: "medium")
ad_banner_loaded(gameId: "sudoku")
mistake_reset_used(difficulty: "hard", uses_this_level: 1)
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

## Shared Audio & Localization

### SoundService

Settings-gated AVAudioPlayer. Games define `AudioConfig` with SFX mappings:

```swift
struct AudioConfig {
    let cellTapSFX: String       // e.g., "sudoku-pencil"
    let correctMoveSFX: String   // e.g., "sudoku-correct"
    let wrongMoveSFX: String     // e.g., "dropRush-wrong"
    let levelCompleteSFX: String // e.g., "dropRush-level-complete"
    let gameOverSFX: String      // e.g., "dropRush-gameover"
}
```

SoundService plays audio when triggered by game events (validated move, level complete, etc.). Users can mute via SettingsView toggle.

### LocalizationService

Manages multi-language strings. Supports English, Spanish, Vietnamese, Portuguese (Brazil), Japanese, Chinese (Simplified).

```swift
enum AppLanguage: String, CaseIterable {
    case en = "English"
    case es = "Español"
    case vi = "Tiếng Việt"
    case ptBR = "Português (Brasil)"
    case ja = "日本語"
    case zhHans = "简体中文"
}
```

Resources stored in `SmartGames/Resources/Localizations/{lang}.lproj/`. String keys follow convention: `game.feature.action` (e.g., `sudoku.pause.resume`, `drop_rush.continue.prompt`).

## Version History

- **Phase 1:** Single-game (Sudoku) scaffold, services, hub, gameplay
- **Phase 2:** Analytics, ads, retention features (daily challenges, statistics)
- **Phase 2.5:** Modular architecture refactor — GameModule protocol, GameRegistry, service decoupling
- **Phase 2.6:** Monetization features — per-game MonetizationConfig, banner ads, rewarded hints, mistake reset ads, 14 monetization events, IAP hint pack UI
- **Phase 3:** Drop Rush game module (30 levels, real-time engine, spawn scheduler, haptics, SFX)
- **Phase 3.1-3.3:** Drop Rush gameplay UI (countdown, HUD, input, pause/result overlays, phase state machine)
- **Phase 3.4-3.6:** Drop Rush monetization (banner ads, interstitials every 2 levels, rewarded continue, 7 new analytics events)
- **Phase 3.7-3.9:** Drop Rush testing (engine tests, progress tests, level definitions validation)
- **Phase 4-4.2:** Sudoku audio & localization (SoundService integration, 6 language support, DropRush+Sudoku SFX configs)
- **Phase 5+:** Advanced monetization (A/B testing), new games, social features
