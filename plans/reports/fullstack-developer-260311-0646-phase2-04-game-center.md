# Phase Implementation Report

## Executed Phase
- Phase: phase-04-game-center
- Plan: /Users/manh.le/github-personal/smartgames/plans/260311-0629-phase2-retention-monetization/
- Status: completed

## Files Modified

| File | Action | Notes |
|------|--------|-------|
| `SmartGames/SharedServices/GameCenter/GameCenterService.swift` | CREATED | 123 lines — auth, submit, display |
| `SmartGames/AppEnvironment.swift` | MODIFIED | Added `gameCenter: GameCenterService` property + init |
| `SmartGames/SmartGamesApp.swift` | MODIFIED | Added `.environmentObject(environment.gameCenter)`, `authenticate()` call in `.task` |
| `SmartGames/ContentView.swift` | MODIFIED | Added `@EnvironmentObject var gameCenter`, passed to `SudokuGameView` |
| `SmartGames/Games/Sudoku/Views/SudokuGameView.swift` | MODIFIED | Added `gameCenterService` param forwarded to ViewModel |
| `SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | MODIFIED | Added `gameCenterService` dep + score submit on win (personal-best check) |
| `SmartGames/Games/Sudoku/Views/SudokuWinView.swift` | MODIFIED | Added "View Leaderboard" button (conditional on `isAuthenticated`) |
| `SmartGames/Games/Sudoku/Views/SudokuLobbyView.swift` | MODIFIED | Added trophy toolbar button (conditional on `isAuthenticated`) |
| `SmartGames/SmartGames.entitlements` | CREATED | `com.apple.developer.game-center: true` |
| `project.yml` | MODIFIED | Added `entitlements` + `capabilities: [gameCenter]` |

## Tasks Completed

- [x] Create `GameCenterService` with auth, submit, display methods
- [x] Wire into `AppEnvironment` and `SmartGamesApp`
- [x] Call `authenticate()` on app launch (non-blocking, in `.task`)
- [x] Submit score on puzzle win in `SudokuGameViewModel` (personal-best gated)
- [x] Wire lobby trophy button to leaderboard display (hidden when unauthenticated)
- [x] Add "View Leaderboard" to `SudokuWinView` (hidden when unauthenticated)
- [x] Handle unauthenticated state gracefully (conditional visibility, no crash)
- [x] Game Center entitlement added to `.entitlements` file
- [x] `xcodegen generate` — succeeded, `GameCenterService.swift` included in build

## Architecture Notes

- `GameCenterService` is `@MainActor` + `ObservableObject` — safe for UI observation
- Auth handler uses `Task { @MainActor in }` to ensure main-thread property updates
- `GameCenterDismissDelegate` (private `NSObject`) handles `GKGameCenterViewController` dismissal
- Score submission: personal-best check done against `statisticsService.stats(for:).bestTimeSeconds` AFTER `recordWin()` updates it — so `<=` comparison is correct (new win already saved)
- `presentViewController` walks to topmost presented controller to avoid "already presenting" crash
- Leaderboard IDs: `com.smartgames.sudoku.leaderboard.{easy|medium|hard|expert}`

## Tests Status
- Type check: not runnable (xcodebuild requires full Xcode, CLI tools only in env)
- Manual syntax review: all files verified — no obvious errors
- XcodeGen: pass (project generated successfully)
- Unit tests: not run (xcodebuild unavailable)

## Issues Encountered
- Another parallel agent (daily-challenge phase) modified `AppEnvironment.swift`, `SmartGamesApp.swift`, `SudokuLobbyView.swift`, and `ContentView.swift` concurrently — reviewed diff after each edit and integrated cleanly; no conflicts
- XcodeGen overwrote entitlements file body to `<dict/>` — manually restored `com.apple.developer.game-center` key after generation
- `xcodebuild` unavailable (command line tools only, not full Xcode) — cannot run compile check

## Next Steps
- Manual App Store Connect setup required: create 4 leaderboards with IDs matching `com.smartgames.sudoku.leaderboard.{easy|medium|hard|expert}`, sort ascending, score range 1–999999
- Test on physical device in Game Center sandbox environment
- Add unit test for `GameCenterService.LeaderboardID.id(for:)` — simple string verification, no GK mocking needed

## Unresolved Questions
- XcodeGen `capabilities: [gameCenter]` syntax may vary by xcodegen version — if entitlement is not applied by Xcode, manually add Game Center capability in Xcode Target > Signing & Capabilities
- Score submission personal-best check: `recordWin()` is called before `submitScore()` so `bestTimeSeconds` is already updated; `<=` is used (not `<`) to handle first-ever win where `bestTimeSeconds` was `Int.max` and now equals `elapsedSeconds`
