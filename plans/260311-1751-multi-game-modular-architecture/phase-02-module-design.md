# Phase 2: Module Design

## Target Folder Structure

```
SmartGames/
  App/
    SmartGamesApp.swift
    AppEnvironment.swift
    ContentView.swift
  Core/
    GameModule.swift          (protocol)
    GameRegistry.swift        (discovers & holds game modules)
    AppRouter.swift
    AppRoute.swift
  FeatureGameHub/
    HubView.swift
    HubViewModel.swift
    Models/
      GameEntry.swift
    Components/
      GameCardView.swift
  Games/
    Sudoku/
      SudokuGameModule.swift  (conforms to GameModule)
      Engine/                 (unchanged)
      Models/                 (unchanged)
      ViewModels/             (unchanged)
      Views/                  (unchanged + ThemePickerView)
      Services/
        SudokuStatisticsService.swift   (renamed from StatisticsService)
        DailyChallengeService.swift     (moved)
        ThemeService.swift              (moved)
  SharedUI/
    AppColors.swift
    AppFonts.swift
    AppTheme.swift
    PrimaryButton.swift
  SharedServices/
    Persistence/
    Settings/
      SettingsService.swift
      SettingsView.swift      (keep here -- app-level settings)
    Sound/
    Ads/
    Analytics/
      AnalyticsEvent.swift
      AnalyticsEvent+Ads.swift
      AnalyticsEvent+AppLifecycle.swift
      (AnalyticsEvent+Sudoku.swift moves to Games/Sudoku/)
    GameCenter/
    Store/
  Configuration/
  Resources/
```

## GameModule Protocol

```swift
/// Contract every game module must conform to.
/// Intentionally minimal -- YAGNI. Expand only when game #2 needs it.
@MainActor
protocol GameModule {
    /// Unique identifier (e.g., "sudoku")
    var id: String { get }

    /// Display name for hub card
    var displayName: String { get }

    /// SF Symbol or asset name for hub card icon
    var iconName: String { get }

    /// Whether the game is playable (false = "Coming Soon" badge)
    var isAvailable: Bool { get }

    /// Returns the lobby/entry view for this game.
    /// Receives AppEnvironment so the game can access shared services.
    func makeLobbyView(environment: AppEnvironment) -> AnyView

    /// Returns routes this game handles.
    /// Used by ContentView to build navigationDestination.
    func navigationDestination(for route: GameRoute, environment: AppEnvironment) -> AnyView?
}
```

### GameRoute (replaces hardcoded AppRoute cases)

```swift
/// Type-erased route that games register.
/// Wraps game-specific route data using Hashable conformance.
struct GameRoute: Hashable {
    let gameId: String
    let routeKey: String      // e.g., "lobby", "game", "stats"
    let parameters: [String: String]  // e.g., ["difficulty": "easy"]

    // Convenience initializers per game live in game module files
}
```

**Alternative (simpler, recommended):** Keep `AppRoute` enum but make it extensible via associated `AnyHashable`:

```swift
enum AppRoute: Hashable {
    case gameLobby(gameId: String)
    case gameScreen(gameId: String, data: AnyHashableData)
    case settings
}
```

**Decision:** Use the simpler `AppRoute` with `gameId` approach. Avoids type-erasure complexity. Games register a routing closure in `GameRegistry` keyed by `gameId`.

### Recommended AppRoute (Final)

```swift
enum AppRoute: Hashable {
    case gameLobby(gameId: String)
    case gamePlay(gameId: String, context: String)  // context = JSON or key
    case settings
}
```

Sudoku internally decodes `context` to get difficulty, daily-challenge flag, etc. Each game owns its context encoding/decoding.

## GameRegistry

```swift
@MainActor
final class GameRegistry: ObservableObject {
    private(set) var modules: [String: GameModule] = [:]

    func register(_ module: GameModule) {
        modules[module.id] = module
    }

    var allGames: [GameModule] {
        Array(modules.values).sorted { $0.id < $1.id }
    }

    func module(for gameId: String) -> GameModule? {
        modules[gameId]
    }
}
```

Registered in `AppEnvironment.init()`:

```swift
let registry = GameRegistry()
registry.register(SudokuGameModule())
self.gameRegistry = registry
```

## Dependency Graph

```
SharedUI          SharedServices
    \                /
     \              /
      v            v
        Core (GameModule, AppRouter, AppRoute)
       /    \
      v      v
FeatureGameHub   Games/Sudoku
                  Games/Future...
```

**Rules:**
- SharedUI imports nothing from SmartGames
- SharedServices imports nothing from SmartGames (only Foundation/UIKit)
- Core imports SharedUI + SharedServices
- FeatureGameHub imports Core + SharedUI (never SharedServices directly)
- Games/* import Core + SharedUI + SharedServices
- Games/* NEVER import other Games/*
- App/ imports everything (thin wiring shell)

## Service Sharing Strategy

**Approach: Pass `AppEnvironment` reference to game modules.**

Games access services via `environment.persistence`, `environment.ads`, etc.
Game-specific services (e.g., `SudokuStatisticsService`) are created and owned
by the game module itself -- not by AppEnvironment.

```swift
struct SudokuGameModule: GameModule {
    // Game-owned services
    private let statisticsService: SudokuStatisticsService
    private let dailyChallengeService: DailyChallengeService
    private let themeService: ThemeService

    init(environment: AppEnvironment) {
        self.statisticsService = SudokuStatisticsService(persistence: environment.persistence)
        self.dailyChallengeService = DailyChallengeService(persistence: environment.persistence)
        self.themeService = ThemeService(persistence: environment.persistence)
    }
}
```

This keeps `AppEnvironment` lean (only truly shared services) while letting games
create their own services using shared infrastructure.

## Navigation Flow

1. `HubView` shows game cards from `GameRegistry.allGames`
2. User taps card -> `router.navigate(to: .gameLobby(gameId: "sudoku"))`
3. `ContentView.navigationDestination` asks `gameRegistry.module(for: gameId)?.makeLobbyView()`
4. Inside Sudoku lobby, navigation uses `.gamePlay(gameId: "sudoku", context: "easy")`
5. ContentView asks Sudoku module to resolve the route

## EnvironmentObject Simplification

Current: 11 individual `.environmentObject()` calls in SmartGamesApp.
Target: Pass `AppEnvironment` as single `@EnvironmentObject` + `GameRegistry`.

```swift
ContentView()
    .environmentObject(environment)
    .environmentObject(environment.gameRegistry)
```

Games that need specific services access them via `environment.persistence`, etc.
Views within games can still use `@EnvironmentObject` for services they need,
injected by the game module's view builder.
