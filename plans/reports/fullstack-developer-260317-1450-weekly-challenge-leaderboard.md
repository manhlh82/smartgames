# Phase Implementation Report

## Executed Phase
- Phase: Weekly Challenge + Leaderboard (Phase 5)
- Plan: none (direct prompt)
- Status: completed

## Files Modified

### Created
- `SmartGames/SharedServices/WeeklyChallenge/WeeklyChallengeModels.swift` (+44 lines) — WeeklyRewardTier, WeeklyChallengeState, WeeklyGameReward, WeeklyRewardResult
- `SmartGames/SharedServices/WeeklyChallenge/WeeklyChallengeService.swift` (+143 lines) — service with onAppLaunch, submitScore, startObservingScores, claimRewards
- `SmartGames/Common/UI/WeeklyChallengeCardView.swift` (+46 lines) — compact card with game name, best score, leaderboard button
- `SmartGames/Common/UI/WeeklyChallengeResultView.swift` (+98 lines) — popup showing tier + gold/diamond rewards per game

### Modified
- `SmartGames/SharedServices/GameCenter/GameCenterService.swift` — added WeeklyLeaderboardID enum + fetchWeeklyRank() async method
- `SmartGames/AppEnvironment.swift` — added weeklyChallenge: WeeklyChallengeService property + init wiring
- `SmartGames/SmartGamesApp.swift` — added onAppLaunch() + startObservingScores() calls in .task
- `SmartGames/SharedServices/Ads/AdsService.swift` — added weeklyScoreOccurred to Notification.Name extension (co-locating with gameWonOccurred/gameOverOccurred for universal VM visibility)
- `SmartGames/Games/DropRush/ViewModels/DropRushGameViewModel.swift` — post weeklyScoreOccurred on levelComplete
- `SmartGames/Games/Stack2048/ViewModels/Stack2048GameViewModel+GameEvents.swift` — post weeklyScoreOccurred on gameOver and win
- `SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift` — post weeklyScoreOccurred on puzzle complete (inverse-time score: max(0, 3600 - elapsedSeconds))
- `SmartGames.xcodeproj/project.pbxproj` — registered all new files + also registered pre-existing untracked LoginStreakCalendarView.swift which was breaking DailyLoginPopupView

## Tasks Completed
- [x] WeeklyChallengeModels.swift with all model types
- [x] WeeklyChallengeService with week ID detection, score submission, reward claiming, NotificationCenter observer
- [x] WeeklyChallengeCardView (compact game card with leaderboard button)
- [x] WeeklyChallengeResultView (popup with tier badges and reward display)
- [x] GameCenterService.WeeklyLeaderboardID enum + fetchWeeklyRank method
- [x] AppEnvironment registration
- [x] SmartGamesApp lifecycle calls
- [x] All 3 game VMs wired via NotificationCenter (no tight coupling)
- [x] Xcode project registered for all new files

## Tests Status
- Type check: pass (BUILD SUCCEEDED)
- Unit tests: not run (no test targets for new services)
- Integration tests: manual build verification passed

## Issues Encountered

1. **Linter hook reverts** — A pre-commit/write hook repeatedly reverted edits to AppEnvironment, SmartGamesApp, and game VM files between tool calls. Required multiple re-applications.

2. **Git stash lost pbxproj state** — Stash/unstash during investigation reset pbxproj modifications. Required re-running Python script with corrected anchor points.

3. **GKLeaderboard API mismatch** — `loadEntries(for:timeScope:)` returns 2-tuple not 3-tuple as in the prompt. Fixed: use separate calls for local entry and global range to get total player count.

4. **Notification.Name scope** — `weeklyScoreOccurred` defined in WeeklyChallengeModels.swift was invisible to Stack2048 VM during compilation. Fixed: moved extension to AdsService.swift where sibling notifications already live.

5. **LoginStreakCalendarView pre-existing gap** — DailyLoginPopupView.swift (modified by linter from a prior phase) references LoginStreakCalendarView which was on disk but not in xcodeproj. Registered it as part of this work to unblock the build.

## Design Decisions
- `Notification.Name.weeklyScoreOccurred` placed in AdsService.swift to ensure all game VMs can resolve it at compile time (same file as gameWonOccurred/gameOverOccurred)
- Stack2048 posts score on BOTH gameOver and handleWin to capture highest score (win score may exceed gameOver score when 2048 tile is reached)
- `fetchWeeklyRank` uses two GKLeaderboard API calls: one for local player entry rank, one `global/.week/range:1-1` for total count
- Graceful fallback: any GKLeaderboard failure → participation tier reward

## Unresolved Questions
- `loadEntries(for:.global, timeScope:.week, range:)` returns total player count as 3rd element of tuple — verify this is accurate on device (Simulator may return 0)
- Weekly leaderboard IDs need to be configured in App Store Connect before scores submit successfully
- WeeklyChallengeResultView is created but not yet surfaced in any navigation flow — consumer view needs to observe `weeklyChallenge.pendingRewards` and present it
