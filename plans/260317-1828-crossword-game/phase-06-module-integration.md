# Phase 06 — Module + Integration

## Context Links
- [plan.md](plan.md) — overview
- Pattern ref: `SmartGames/Games/Sudoku/SudokuModule.swift`
- Pattern ref: `SmartGames/AppEnvironment.swift`
- Pattern ref: `SmartGames/SmartGamesApp.swift`

## Overview
- **Priority:** P1
- **Status:** pending
- Create CrosswordModule conforming to GameModule protocol, register in AppEnvironment, inject daily challenge service, add analytics events, update project.yml.

## Requirements

### CrosswordModule.swift
Follow `SudokuGameModule` pattern:
```
@MainActor final class CrosswordModule: GameModule
  let id = "crossword"
  let displayName = "Crossword"
  let iconName = "icon-crossword"
  let isAvailable = true
  var audioConfig: (any AudioConfig)? { nil }  // no custom audio V1

  var monetizationConfig: MonetizationConfig {
    MonetizationConfig(
      bannerEnabled: true,
      interstitialEnabled: true,
      interstitialFrequency: 2,
      rewardedHintsEnabled: true,
      rewardedHintAmount: 3,
      levelCompleteHintReward: 1,
      maxHintCap: 5,
      mistakeResetEnabled: false
    )
  }

  private let puzzleBank: CrosswordPuzzleBank

  init(persistence: PersistenceService)
  func makeLobbyView(environment:) -> AnyView
  func navigationDestination(for:environment:) -> AnyView?
```

Route contexts: "mini", "standard", "daily"

### AppEnvironment.swift Changes
- Add property: `let crosswordDailyChallenge: CrosswordDailyChallengeService`
- Init: instantiate after gold/gameCenter, before registry
- Register: `let crossword = CrosswordModule(persistence: persistence)` + `registry.register(crossword)`

### SmartGamesApp.swift Changes
- Add `.environmentObject(env.crosswordDailyChallenge)`

### project.yml Changes
- Add all Crossword files to sources
- Add `crossword-puzzles.json` to resources

### AnalyticsEvent+Crossword.swift (new)
Add analytics event factories:
```swift
extension AnalyticsEvent {
  static func crosswordStarted(difficulty: String) -> AnalyticsEvent
  static func crosswordCompleted(difficulty: String, hintsUsed: Int, timeSeconds: Int) -> AnalyticsEvent
  static func crosswordAbandoned(difficulty: String) -> AnalyticsEvent
  static func crosswordHintUsed(type: String, difficulty: String) -> AnalyticsEvent
  static func crosswordUndoUsed(difficulty: String) -> AnalyticsEvent
  static func crosswordDiamondHintUsed(difficulty: String) -> AnalyticsEvent
}
```

### Icon Asset
- Add `icon-crossword` to Assets.xcassets (grid-pattern icon)

## Related Code Files
- **Create:** `SmartGames/Games/Crossword/CrosswordModule.swift`
- **Create:** `SmartGames/SharedServices/Analytics/AnalyticsEvent+Crossword.swift`
- **Modify:** `SmartGames/AppEnvironment.swift`
- **Modify:** `SmartGames/SmartGamesApp.swift`
- **Modify:** `project.yml`
- **Add:** `SmartGames/Assets.xcassets/icon-crossword.imageset/`

## Implementation Steps
1. Create `CrosswordModule.swift` — implement GameModule protocol
2. Create `AnalyticsEvent+Crossword.swift` — all event factories
3. Modify `AppEnvironment.swift`:
   - Add `crosswordDailyChallenge` property
   - Instantiate service in init
   - Register `CrosswordModule`
4. Modify `SmartGamesApp.swift`:
   - Inject `.environmentObject(env.crosswordDailyChallenge)`
5. Add icon-crossword asset (placeholder SF Symbol or custom)
6. Update `project.yml` — add Crossword source glob and JSON resource
7. Run `xcodegen generate`
8. Compile check — all phases integrated

## Todo List
- [ ] CrosswordModule.swift
- [ ] AnalyticsEvent+Crossword.swift
- [ ] AppEnvironment: add service + register module
- [ ] SmartGamesApp: inject environmentObject
- [ ] Icon asset
- [ ] project.yml update
- [ ] xcodegen generate
- [ ] Full compile check

## Success Criteria
- Crossword appears in Hub game list
- Tapping Crossword navigates to lobby
- Lobby → difficulty → game view → play → win all works end-to-end
- Daily challenge accessible from lobby
- Analytics events fire correctly
- No compile errors
