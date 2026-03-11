# Phase 4: Game Center Leaderboards

## Context Links
- [SudokuGameViewModel.swift](../../SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift) -- win handler, score source
- [SudokuDifficulty.swift](../../SmartGames/Games/Sudoku/Models/SudokuDifficulty.swift) -- difficulty enum
- [AppEnvironment.swift](../../SmartGames/AppEnvironment.swift)
- [SudokuLobbyView.swift](../../SmartGames/Games/Sudoku/Views/SudokuLobbyView.swift) -- trophy icon placeholder
- [SudokuWinView.swift](../../SmartGames/Games/Sudoku/Views/SudokuWinView.swift) -- post-win screen

## Overview
- **Priority:** P2 -- requires Apple Developer setup + entitlement
- **Status:** ✅ Complete
- **Effort:** 5h
- **Description:** Integrate GameKit for Game Center authentication and leaderboard score submission. One leaderboard per difficulty (best time, lower is better). Native Game Center UI for viewing leaderboards.

## Key Insights
- GameKit is a system framework -- no SPM/CocoaPods dependency needed
- `GKLocalPlayer.local.authenticateHandler` must be called early (app launch)
- Score submission is fire-and-forget async -- `GKLeaderboard.submitScore()`
- Native `GKGameCenterViewController` handles leaderboard display (no custom UI needed for MVP)
- Lobby already has a placeholder trophy icon in toolbar -- wire it up
- App Store Connect setup required: create 4 leaderboard IDs

## Requirements

### Functional
- FR1: Authenticate Game Center player on app launch (silent if previously authenticated)
- FR2: Submit best time (seconds) to per-difficulty leaderboard on puzzle win
- FR3: Trophy icon in lobby opens Game Center leaderboard viewer
- FR4: Win screen shows "View Leaderboard" link when Game Center authenticated
- FR5: Graceful degradation -- if not authenticated, trophy icon shows sign-in prompt or is hidden

### Non-Functional
- NFR1: Auth must not block app launch or show UI unless user taps
- NFR2: Score submission must not block game flow (async, fire-and-forget)
- NFR3: Works offline -- GameKit queues scores for later submission

## Architecture

### Leaderboard IDs (App Store Connect)
```
com.smartgames.sudoku.leaderboard.easy
com.smartgames.sudoku.leaderboard.medium
com.smartgames.sudoku.leaderboard.hard
com.smartgames.sudoku.leaderboard.expert
```

### GameCenterService
```swift
import GameKit

@MainActor
final class GameCenterService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var localPlayerName: String?

    func authenticate()                                          // call on app launch
    func submitScore(_ seconds: Int, difficulty: SudokuDifficulty)  // fire-and-forget
    func showLeaderboard(for difficulty: SudokuDifficulty?)       // nil = show all

    static func leaderboardID(for difficulty: SudokuDifficulty) -> String {
        "com.smartgames.sudoku.leaderboard.\(difficulty.rawValue)"
    }
}
```

### Authentication Flow
```
App launch → GKLocalPlayer.local.authenticateHandler = { vc, error in
    if let vc:  present sign-in VC (only on first launch or if user taps)
    if authenticated:  set isAuthenticated = true
    if error:  silently ignore, set isAuthenticated = false
}
```

### Score Submission Flow
```
Win → SudokuGameViewModel.checkWin()
   → gameCenterService.submitScore(elapsedSeconds, difficulty)
   → GKLeaderboard.submitScore(elapsedSeconds, context: 0, player: localPlayer,
                                leaderboardIDs: [leaderboardID])
```

Score type: **elapsed seconds** (lower is better). Game Center supports "smallest value" sort.

## Files to Create

| File | Purpose |
|------|---------|
| `SharedServices/GameCenter/GameCenterService.swift` | Auth, score submission, leaderboard display |

## Files to Modify

| File | Change |
|------|--------|
| `AppEnvironment.swift` | Add `let gameCenter: GameCenterService` |
| `SmartGamesApp.swift` | Inject `GameCenterService`, call `authenticate()` in `.task` |
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Add `GameCenterService` dependency; submit score on win |
| `Games/Sudoku/Views/SudokuLobbyView.swift` | Wire trophy button to `gameCenterService.showLeaderboard()` |
| `Games/Sudoku/Views/SudokuWinView.swift` | Add "View Leaderboard" button (visible when authenticated) |
| `SmartGames.entitlements` | Add Game Center entitlement (Xcode capability) |
| `project.yml` (XcodeGen) | Add GameCenter capability if using XcodeGen |

## Implementation Steps

1. **Enable Game Center entitlement**
   - In Xcode: Target → Signing & Capabilities → + Game Center
   - Or add to `project.yml` under capabilities
   - This creates/updates `.entitlements` file

2. **Create `GameCenterService.swift`**
   ```swift
   import GameKit

   @MainActor
   final class GameCenterService: ObservableObject {
       @Published var isAuthenticated = false
       @Published var localPlayerName: String?

       func authenticate() {
           GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
               Task { @MainActor in
                   if let vc = viewController {
                       // Present Game Center sign-in
                       self?.presentViewController(vc)
                   }
                   self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                   self?.localPlayerName = GKLocalPlayer.local.isAuthenticated
                       ? GKLocalPlayer.local.displayName : nil
               }
           }
       }

       func submitScore(_ seconds: Int, difficulty: SudokuDifficulty) {
           guard isAuthenticated else { return }
           let leaderboardID = Self.leaderboardID(for: difficulty)
           Task {
               try? await GKLeaderboard.submitScore(
                   seconds, context: 0,
                   player: GKLocalPlayer.local,
                   leaderboardIDs: [leaderboardID]
               )
           }
       }

       func showLeaderboard(for difficulty: SudokuDifficulty? = nil) {
           guard isAuthenticated else { return }
           let gcVC = GKGameCenterViewController(state: .leaderboards)
           if let diff = difficulty {
               gcVC.leaderboardIdentifier = Self.leaderboardID(for: diff)
           }
           presentViewController(gcVC)
       }

       private func presentViewController(_ vc: UIViewController) {
           guard let rootVC = UIApplication.shared.connectedScenes
               .compactMap({ $0 as? UIWindowScene })
               .flatMap({ $0.windows })
               .first(where: { $0.isKeyWindow })?
               .rootViewController else { return }
           rootVC.present(vc, animated: true)
       }

       static func leaderboardID(for difficulty: SudokuDifficulty) -> String {
           "com.smartgames.sudoku.leaderboard.\(difficulty.rawValue)"
       }
   }
   ```

3. **Wire into `AppEnvironment`**
   - Add `let gameCenter: GameCenterService`
   - Init: `self.gameCenter = GameCenterService()`

4. **Update `SmartGamesApp.swift`**
   - Add `.environmentObject(environment.gameCenter)`
   - In `.task`: `environment.gameCenter.authenticate()`

5. **Update `SudokuGameViewModel`**
   - Add `let gameCenter: GameCenterService` to init
   - In `checkWin()` after `saveStats()`: `gameCenter.submitScore(elapsedSeconds, difficulty: puzzle.difficulty)`

6. **Update `SudokuLobbyView`**
   - Wire trophy toolbar button:
     ```swift
     Button { gameCenterService.showLeaderboard() } label: {
         Image(systemName: "trophy")
     }
     .disabled(!gameCenterService.isAuthenticated)
     ```

7. **Update `SudokuWinView`**
   - Add optional "View Leaderboard" button below "Back to Menu"
   - Only visible when `gameCenterService.isAuthenticated`

8. **App Store Connect setup** (manual, document steps)
   - Create 4 leaderboards with IDs matching the pattern
   - Score format: "Elapsed Time" (smallest is best)
   - Sort order: ascending
   - Score range: 1 - 999999 (seconds)

## Todo List

- [ ] Enable Game Center entitlement in Xcode project
- [ ] Create `GameCenterService` with auth, submit, display methods
- [ ] Wire into `AppEnvironment` and `SmartGamesApp`
- [ ] Call `authenticate()` on app launch
- [ ] Submit score on puzzle win in `SudokuGameViewModel`
- [ ] Wire lobby trophy button to leaderboard display
- [ ] Add "View Leaderboard" to `SudokuWinView`
- [ ] Handle unauthenticated state gracefully (hide/disable buttons)
- [ ] Create 4 leaderboards in App Store Connect
- [ ] Test on physical device (Game Center sandbox)

## Acceptance Criteria

- [ ] Game Center auth prompt appears on first launch (or silently authenticates returning users)
- [ ] Winning a puzzle submits elapsed time to correct difficulty leaderboard
- [ ] Trophy button opens native Game Center leaderboard UI
- [ ] Unauthenticated state: trophy disabled, no crash
- [ ] Score submission does not block win screen display
- [ ] Works in Game Center sandbox environment

## Tests Needed

- `GameCenterService.leaderboardID(for:)`: verify correct ID string per difficulty
- `GameCenterService`: mock `GKLocalPlayer` to test auth state propagation (limited by GameKit testability)
- Integration: verify `submitScore` called exactly once per win
- Verify no crash when `isAuthenticated == false` and user taps trophy

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Game Center sandbox unreliable | Medium | Test on real device; sandbox issues are well-documented |
| GKGameCenterViewController dismiss delegate | Low | Implement `GKGameCenterControllerDelegate.gameCenterViewControllerDidFinish` |
| App Store Connect leaderboard setup errors | Low | Document exact setup steps; verify IDs match code |

## Security Considerations
- Game Center handles all player identity -- no custom auth needed
- Scores validated by GameKit -- no server-side anti-cheat needed for MVP
- No PII stored locally

## Next Steps
- Daily Challenge leaderboard (Phase 3 integration) -- separate leaderboard for daily best times
- Friends leaderboard filter (Phase 3+)
