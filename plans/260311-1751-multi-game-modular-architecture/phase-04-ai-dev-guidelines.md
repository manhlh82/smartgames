# Phase 4: AI-Friendly Development Guidelines

## Scoping Claude Prompts Per Module

### Working in FeatureSudoku Only
```
Scope: Only modify files under SmartGames/Games/Sudoku/
You may READ (not edit): Core/GameModule.swift, SharedUI/*, SharedServices/*
Do not touch: FeatureGameHub/*, App/*, other Games/*
```

### Working in SharedServices Only
```
Scope: Only modify files under SmartGames/SharedServices/
Do not touch: Games/*, FeatureGameHub/*, App/*
Constraint: No SwiftUI imports in service files (except SettingsView)
```

### Working on a New Game
```
Scope: Create files under SmartGames/Games/{NewGame}/
You may READ: Core/GameModule.swift (protocol to conform to)
You may READ: Games/Sudoku/ (as reference pattern)
Do not edit: Games/Sudoku/*, SharedServices/*, Core/*
Registration: Add your GameModule to AppEnvironment.init() only
```

## File Ownership Rules

| Module | Owner | Can Import |
|--------|-------|-----------|
| `App/` | Lead/orchestrator only | Everything |
| `Core/` | Lead only | SharedUI, SharedServices |
| `FeatureGameHub/` | Hub developer | Core, SharedUI |
| `Games/Sudoku/` | Sudoku developer | Core, SharedUI, SharedServices |
| `Games/{NewGame}/` | Game developer | Core, SharedUI, SharedServices |
| `SharedUI/` | Design/UI developer | Foundation only |
| `SharedServices/` | Platform developer | Foundation, UIKit |

## Adding a New Game (Zero Existing Code Changes)

### Step 1: Create folder structure
```
Games/{NewGame}/
  {NewGame}GameModule.swift
  Engine/
  Models/
  ViewModels/
  Views/
  Services/     (if game-specific services needed)
```

### Step 2: Implement GameModule protocol
```swift
struct {NewGame}GameModule: GameModule {
    let id = "{newgame}"
    let displayName = "{New Game}"
    let iconName = "icon-{newgame}"
    let isAvailable = true   // false for "Coming Soon"

    func makeLobbyView(environment: AppEnvironment) -> AnyView {
        AnyView({NewGame}LobbyView(environment: environment))
    }

    func navigationDestination(for route: AppRoute, environment: AppEnvironment) -> AnyView? {
        // Handle .gamePlay(gameId: "{newgame}", context: ...)
    }
}
```

### Step 3: Register in AppEnvironment (1 line)
```swift
registry.register({NewGame}GameModule())
```

### Step 4: Add analytics events
```
SharedServices/Analytics/AnalyticsEvent+{NewGame}.swift  // if shared events
Games/{NewGame}/AnalyticsEvent+{NewGame}.swift           // if game-specific
```

**Files touched in existing code: 1 (AppEnvironment.swift, 1 line)**

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Game module struct | `{Name}GameModule` | `SudokuGameModule` |
| Game folder | `Games/{Name}/` | `Games/Sudoku/` |
| Game-specific service | `{Name}{Service}Service` | `SudokuStatisticsService` |
| Game route context | `{name}.{action}` | `sudoku.game`, `sudoku.daily` |
| Persistence keys | `{name}.{domain}.{key}` | `sudoku.stats.easy` |
| Analytics events | `{name}_{event}` | `sudoku_game_started` |
| Asset prefix | `icon-{name}` | `icon-sudoku` |

## Testing Strategy Per Module

### Engine/ (Unit Tests)
- Pure logic, no UI or service dependencies
- Test: generation, solving, validation, puzzle bank
- 100% testable in isolation
- File pattern: `Tests/Games/{Name}/Engine/*Tests.swift`

### ViewModels/ (Unit Tests)
- Mock services via protocol (or pass real PersistenceService with temp store)
- Test: state transitions, computed properties, user action handlers
- File pattern: `Tests/Games/{Name}/ViewModels/*Tests.swift`

### Views/ (Preview + Manual)
- SwiftUI previews with mock data
- Snapshot tests optional (not required for MVP)
- No unit tests for pure layout code

### Services/ (Unit Tests)
- Test with in-memory PersistenceService
- Test: data persistence, business rules, edge cases
- File pattern: `Tests/SharedServices/*Tests.swift` or `Tests/Games/{Name}/Services/*Tests.swift`

### Integration Tests
- Test GameModule registration + navigation flow
- Test: registry -> hub card -> lobby view -> game view
- File pattern: `Tests/Integration/*Tests.swift`

## Module Boundary Enforcement (Manual Until Swift Packages)

Since folder modules don't enforce import boundaries at compile time:

1. **Code review rule:** PRs modifying `Games/Sudoku/` must not add imports from `Games/{Other}/`
2. **Grep check before merge:**
   ```bash
   # Should return empty for any game module
   grep -r "import.*Games/" SmartGames/Games/Sudoku/ | grep -v "Games/Sudoku"
   ```
3. **CI lint (future):** Add script that fails if cross-game imports detected

## Unresolved Questions

- Should `SettingsView` stay in SharedServices or move to a FeatureSettings module?
  Recommendation: keep in SharedServices until settings become game-specific.
- Should game modules receive `AppEnvironment` or individual services?
  Recommendation: `AppEnvironment` for simplicity. Refine to protocols when testing demands it.
- How to handle deep links routing to a specific game?
  Recommendation: URL scheme maps to `AppRoute.gamePlay(gameId:context:)`. Defer until needed.
