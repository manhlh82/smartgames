# Code Review: Monetization & Gameplay — PR-11 through PR-16 + Fixes

**Date:** 2026-03-12
**Scope:** 9 commits from 667ce13 (base) to HEAD
**Files reviewed:** 17 key files + supporting services

---

## Overall Assessment

The monetization implementation (banner, interstitial, rewarded hints/mistake-reset) is well-structured and follows a clean coordinator pattern. The analytics event coverage is thorough. The code compiles cleanly and the file sizes are all within the 200-line limit. Three bugs were found and fixed: a critical resume-state-loss bug, an ad guard gap on the lost-overlay continue button, and a staleness bug in the lobby saved-game check. One structural fix was applied to the pause button.

---

## Issues Found & Fixed

### Critical

**1. Resume Flow Lost All Game State (FIXED)**
- **File:** `SudokuGameViewModel.swift`
- **Problem:** `resumeSavedGame()` in `SudokuLobbyView` saved only `state.puzzle` to `sudokuPendingPuzzle`, then navigated to the game. `SudokuModule.sudokuGameView()` loaded the puzzle and created a new `SudokuGameViewModel`, which started fresh with `elapsedSeconds=0`, `mistakeCount=0`, empty undo stack. The `hintsRemaining` was loaded from `sudokuHintsRemaining` (persistent hint balance) but all in-game state was wiped.
- **Root cause:** The VM `init` didn't check for and restore `sudokuActiveGame`.
- **Fix:** Modified `SudokuGameViewModel.init` to load `sudokuActiveGame` from persistence; if the puzzle IDs match, restores the full saved state (`elapsedSeconds`, `mistakeCount`, `hintsRemaining`, `hintsUsedTotal`, `undoStack`, `mistakeResetUsesThisLevel`). Also sets `isResume: true` in the analytics event. The lobby `resumeSavedGame()` flow is unchanged — it correctly leaves `sudokuActiveGame` in place and the VM now picks it up.

### Important

**2. "Watch Ad to Continue" on Lost Overlay Had No Ad-Readiness Guard (FIXED)**
- **File:** `SudokuGameView.swift` — `lostOverlay`
- **Problem:** The hint and mistake-reset ad buttons both guard `viewModel.ads.isRewardedAdReady` before calling `showRewardedAd`, showing `showAdUnavailableAlert` when not ready. The "Watch Ad to Continue" button on the lost overlay had no such guard — it called `showRewardedAd` directly, which falls through to `rootViewController` lookup, and silently calls `completion(false)` (no feedback to user).
- **Fix:** Added the same `isRewardedAdReady` guard with `adUnavailable` analytics event and `showAdUnavailableAlert = true` to match behavior of other ad buttons.

**3. Pause Button Active During Ad Prompt Phases (FIXED)**
- **File:** `SudokuGameView.swift` — `gameToolbar`
- **Problem:** When `gamePhase == .needsHintAd` or `.needsMistakeResetAd`, the pause toolbar button was tappable. Tapping it called `viewModel.pause()` which guards `gamePhase == .playing` (so it's a no-op), but the button appearance showed "pause" icon suggesting interactivity, and was inconsistent with `SudokuToolbarView` which correctly disables during non-playing phases.
- **Fix:** Added `.disabled(viewModel.gamePhase != .playing && viewModel.gamePhase != .paused)` to the pause/resume toolbar button.

### Minor

**4. `SudokuLobbyViewModel.checkForSavedGame()` Didn't Clear Stale State (FIXED)**
- **File:** `SudokuLobbyViewModel.swift`
- **Problem:** If `checkForSavedGame()` was called after the saved game was deleted (e.g., externally or via `clearSavedGame()` + re-check), the `else` branch was missing. `hasSavedGame` and `savedGameDifficulty` would retain stale values from the `init` call.
- **Fix:** Added `else` branch to reset `hasSavedGame = false` and `savedGameDifficulty = nil`.

**5. `SudokuLobbyViewModel.init` Duplicated `checkForSavedGame()` Call (FIXED)**
- **File:** `SudokuLobbyViewModel.swift`
- **Problem:** `checkForSavedGame()` was called in both `init` and `SudokuLobbyView.onAppear`. The `onAppear` call is the right place (it refreshes on return from game). The `init` call was redundant since the view's `onAppear` always fires on first display.
- **Fix:** Removed `checkForSavedGame()` from `init`. The `onAppear` call in `SudokuLobbyView` is preserved.

---

## Button Audit Results

| Screen | Element | Status | Notes |
|--------|---------|--------|-------|
| **Lobby** | Difficulty rows (Easy/Medium/Hard/Expert) | PASS | Calls `startNewGame(difficulty:)` correctly |
| **Lobby** | Resume button | PASS | Calls `resumeSavedGame()` — correctly leaves `sudokuActiveGame` for VM to restore |
| **Lobby** | New Game (discard) button | PASS | Calls `viewModel.clearSavedGame()` |
| **Lobby** | Daily Challenge card | PASS | Navigates `.gamePlay(gameId: "sudoku", context: "daily")` |
| **Lobby** | Leaderboard toolbar button | PASS | Guarded by `gameCenterService.isAuthenticated` |
| **Lobby** | Statistics toolbar button | PASS | Navigates `.gamePlay(gameId: "sudoku", context: "statistics")` |
| **Lobby** | Theme picker toolbar button | PASS | Presents sheet correctly |
| **Lobby** | Theme picker Done button | PASS | Dismisses sheet |
| **Game** | Back (chevron.left) toolbar | PASS | Calls `viewModel.autoSave()` then `router.pop()` |
| **Game** | Pause/Resume toolbar | PASS (fixed) | Now disabled during ad phases |
| **Game** | Stats bar mistake reset button | PASS | Guarded by `canResetMistakes`, calls `requestMistakeReset()` |
| **Game** | Toolbar: Undo | PASS | Disabled when `!isUndoAvailable` |
| **Game** | Toolbar: Eraser | PASS | Disabled when `!isEraseAvailable` |
| **Game** | Toolbar: Pencil | PASS | Toggle on tap, auto-fill on long-press |
| **Game** | Toolbar: Hint | PASS | Calls `useHint()` which guards phase and hint count |
| **Game** | Number pad 1-9 | PASS | Disabled for completed numbers, calls `placeNumber(_:)` |
| **Game** | Hint ad alert: Watch Ad | PASS | Guards `isRewardedAdReady`, shows unavailable alert if not ready |
| **Game** | Hint ad alert: Cancel | PASS | Calls `cancelHintAd()` |
| **Game** | Mistake reset alert: Watch Ad | PASS | Guards `isRewardedAdReady` |
| **Game** | Mistake reset alert: Cancel | PASS | Calls `cancelMistakeResetAd()` |
| **Game** | Ad Unavailable alert: OK | PASS | Dismisses via `role: .cancel` |
| **Game** | Restart confirm: Restart | PASS | `role: .destructive`, calls `viewModel.restart()` |
| **Game** | Restart confirm: Cancel | PASS | `role: .cancel` |
| **Game** | Pause overlay: Resume | PASS | Calls `viewModel.resume()` |
| **Game** | Pause overlay: Restart | PASS | Sets `showRestartConfirm = true` |
| **Game** | Pause overlay: Quit | PASS | Calls `router.popToRoot()` |
| **Lost overlay** | Try Again | PASS | Calls `viewModel.restart()` |
| **Lost overlay** | New Game | PASS | Calls `router.pop()` |
| **Lost overlay** | Watch Ad to Continue | PASS (fixed) | Now guards `isRewardedAdReady` |
| **Win screen** | Next Puzzle | PASS | Calls `onNextPuzzle` → `router.pop()` |
| **Win screen** | Back to Menu | PASS | Calls `onBackToMenu` → `router.popToRoot()` |
| **Win screen** | View Leaderboard | PASS | Guarded by `gameCenterService.isAuthenticated` |
| **Settings** | Sound Effects toggle | PASS | Bound to `settings.isSoundEnabled` |
| **Settings** | Haptics toggle | PASS | Bound to `settings.isHapticsEnabled` |
| **Settings** | Highlight Related Cells toggle | PASS | Bound to `settings.highlightRelatedCells` |
| **Settings** | Highlight Same Numbers toggle | PASS | Bound to `settings.highlightSameNumbers` |
| **Settings** | Show Timer toggle | PASS | Bound to `settings.showTimer` |
| **Settings** | Remove Ads button | PASS | Presents `PaywallView` sheet |
| **Settings** | Get Hint Pack button | PASS | Presents `PaywallView` sheet |
| **Settings** | Privacy Policy link | PASS | Links to URL |
| **Settings** | Terms of Service link | PASS | Links to URL |

---

## Logic Review

### Hint Cap Math (`grantHints`)
- `effectiveAmount = min(amount, maxHintCap - hintsRemaining)` — correct; prevents exceeding cap
- IAP `bypassCap: true` path grants exactly `amount` with no ceiling — correct
- `hintCapReached` analytics fires when `effectiveAmount <= 0` — correct
- `canWatchAdForHints` = `hintsRemaining < maxHintCap` — prevents offering ad when IAP has pushed hints above cap — correct

### Mistake Reset Logic
- `canResetMistakes` guards: `mistakeCount > 0`, phase is `.playing`, feature enabled, `mistakeResetUsesThisLevel < limit` — all correct
- `requestMistakeReset()` guards `canResetMistakes` — correct
- `grantMistakeResetAfterAd()` sets `mistakeCount = 0`, increments `mistakeResetUsesThisLevel`, fires analytics — correct
- `mistakeResetUsesThisLevel` resets to 0 in `restart()` — correct

### Interstitial Frequency Math
- `shouldShowAfterLevelComplete()` increments `completedLevelCount` then checks `completedLevelCount % frequency == 0`
- With `frequency = 1`: first call → count=1, `1 % 1 = 0` → shows. Correct.
- With `frequency = 3`: shows on levels 3, 6, 9... Correct.
- `configure(frequency:)` called on every win (from `checkWin()`) — idempotent, no issue.
- `isAdReady` checked before modulo — ad must be loaded to show. Correct.

### `checkWin()` Flow
- Stops timer, plays sound/haptics, records stats, marks daily challenge — correct
- Deletes `sudokuActiveGame` — correct (clears save so lobby doesn't offer resume)
- Grants level-completion hint (capped) — correct
- Shows interstitial if frequency met and not ads-removed — correct
- Game Center score submitted only if personal best — correct (uses `<=` comparison)

### `observeHintGrants()` (IAP polling)
- 200ms polling loop watching `store.pendingHintGrant`
- Works but is a busy-wait anti-pattern. Low risk at 200ms interval; acceptable for now.
- Correctly uses `weak` refs to avoid retain cycle.

---

## Simplifications Applied

None needed. All files are under 200 lines. No dead code found. Logic is clean and appropriately decomposed.

---

## Positive Observations

- `GamePhase` enum covering all states cleanly — good pattern for driving overlays and guards
- `canResetMistakes` and `canWatchAdForHints` as computed properties keep ad-offering conditions DRY and testable
- `grantHints(_:bypassCap:)` clearly separates IAP from ad grant semantics
- `@discardableResult` on `grantHints` is appropriate
- `scheduleAutoSave()` debounce pattern prevents excessive UserDefaults writes
- `storeService` as `weak var` on VM prevents reference cycles with the store
- `BannerAdCoordinator` correctly uses `weak var analytics` — no leak
- All ad buttons show `showAdUnavailableAlert` consistently (now including lost overlay)
- `SudokuGameState.mistakeResetUsesThisLevel` defaults to 0 for backward-compatible decode — good

---

## Remaining Concerns

1. **`observeHintGrants()` polling (200ms)**: Should be replaced with Combine or async stream when StoreKit observation is refactored. Not urgent; no user-facing impact.
2. **`SudokuBoardUtils.peers()` called on every render** in `highlightState(for:)`: For each of 81 cells on every board update. Consider caching peers per position at game start. Not urgent given SwiftUI's diffing.
3. **`rootViewController` computed property in `AdsService`**: Uses deprecated `windows` API (`UIApplication.shared.connectedScenes...windows`). In iOS 16+, prefer `UIWindowScene.keyWindow`. Low priority for now.
4. **`DailyChallengeView.cornerRadius(_:)` extension conflict**: Defines `cornerRadius(_ radius: CGFloat)` as a private extension on `View` which shadows `SwiftUI.View.cornerRadius(_:)`. Won't cause runtime issues but may cause confusion. Same pattern exists in `SudokuLobbyView`. These should be unified or removed if SwiftUI's built-in suffices.
5. **`SudokuLobbyViewModel.loadSavedGame()`**: Now effectively unused since resume state is restored by VM init. The method is still needed by `resumeSavedGame()` in `SudokuLobbyView` to get `state.puzzle` for navigation context. Safe.

---

## Files Fixed

| File | Change |
|------|--------|
| `SudokuGameViewModel.swift` | Restore full saved game state on resume; fix analytics `isResume` flag |
| `SudokuGameView.swift` | Disable pause button during ad phases; add ad-readiness guard to lost overlay continue button |
| `SudokuLobbyViewModel.swift` | Clear stale saved-game state in `checkForSavedGame()` else-branch; remove duplicate init call |
