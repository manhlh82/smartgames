# Phase 3: Migration Plan

## Guiding Principle

**App must compile and run after every PR.** No big-bang refactors. Each PR is independently mergeable and reviewable.

---

## PR-11: Create GameModule Protocol + GameRegistry

**Goal:** Define the plug-in contract without moving any files.

**Approach:** Add new files only.

**Files created:**
- `SmartGames/Core/GameModule.swift` -- protocol definition
- `SmartGames/Core/GameRegistry.swift` -- module registry

**Files modified:**
- None

**Acceptance criteria:**
- [ ] `GameModule` protocol compiles with all required properties/methods
- [ ] `GameRegistry` can register and retrieve modules
- [ ] No existing code modified
- [ ] App compiles and runs identically to before
- [ ] Unit test for GameRegistry register/retrieve

**Risk:** LOW -- additive only, no behavioral changes
**Claude safe:** YES -- isolated new files, no dependencies on existing code

---

## PR-12: Create SudokuGameModule Conformance

**Goal:** Make Sudoku conform to `GameModule` protocol alongside existing routing.

**Approach:** Create `SudokuGameModule` that wraps existing views. Dual routing: old `AppRoute` cases still work, new protocol is wired but not yet used by Hub.

**Files created:**
- `SmartGames/Games/Sudoku/SudokuGameModule.swift` (replace existing stub)

**Files modified:**
- `SmartGames/AppEnvironment.swift` -- add `gameRegistry` property, register SudokuGameModule
- `SmartGames/SmartGamesApp.swift` -- inject gameRegistry as environmentObject

**Acceptance criteria:**
- [ ] `SudokuGameModule` conforms to `GameModule`
- [ ] `makeLobbyView()` returns `SudokuLobbyView` wrapped in AnyView
- [ ] `AppEnvironment.gameRegistry` is populated on launch
- [ ] Old navigation still works (no behavior change)
- [ ] App compiles and runs

**Risk:** LOW -- existing routing untouched, new code runs in parallel
**Claude safe:** YES -- only 3 files touched, clear boundaries

---

## PR-13: Refactor AppRoute to Support Dynamic Games

**Goal:** Replace Sudoku-specific route cases with generic game routes.

**Approach:** Change `AppRoute` enum to use `gameLobby(gameId:)` and `gamePlay(gameId:context:)`. Update `ContentView` to resolve routes via `GameRegistry`. Remove hardcoded Sudoku view construction from ContentView.

**Files modified:**
- `SmartGames/Navigation/AppRoutes.swift` -- new enum cases (keep old as deprecated temporarily)
- `SmartGames/ContentView.swift` -- route resolution via GameRegistry
- `SmartGames/Games/Sudoku/SudokuGameModule.swift` -- implement `navigationDestination(for:)`
- `SmartGames/Games/Sudoku/Views/SudokuLobbyView.swift` -- use new route format

**Files deleted:**
- None (old routes removed after Hub migration in PR-14)

**Acceptance criteria:**
- [ ] `ContentView` no longer imports Sudoku types directly
- [ ] Navigation through new routes works end-to-end
- [ ] Old routes still compile (deprecated, used by tests/deep-links if any)
- [ ] App compiles and all navigation paths work
- [ ] No Sudoku-specific logic in ContentView

**Risk:** MEDIUM -- navigation is critical path; thorough manual testing needed
**Mitigation:** Keep old routes as deprecated until PR-14 confirms new routing works
**Claude safe:** YES -- with constraint: must test all navigation flows

---

## PR-14: Migrate Hub to Use GameRegistry

**Goal:** Hub discovers games from GameRegistry instead of hardcoded array.

**Approach:** `HubViewModel` reads from `GameRegistry.allGames`. `GameEntry` built from `GameModule` properties. Move Hub files to `FeatureGameHub/` folder.

**Files moved:**
- `SmartGames/Hub/*` -> `SmartGames/FeatureGameHub/`
- `SmartGames/Common/Components/GameCardView.swift` -> `SmartGames/FeatureGameHub/Components/`

**Files modified:**
- `SmartGames/FeatureGameHub/HubViewModel.swift` -- read from GameRegistry
- `SmartGames/FeatureGameHub/Models/GameEntry.swift` -- remove `route: AppRoute?`, add `gameId: String`
- `SmartGames/FeatureGameHub/HubView.swift` -- navigate via `gameLobby(gameId:)`

**Acceptance criteria:**
- [ ] Hub shows Sudoku card via GameRegistry (not hardcoded)
- [ ] Adding a game = registering a GameModule (no Hub edits)
- [ ] GameCardView works with new GameEntry model
- [ ] Folder structure matches plan
- [ ] App compiles and runs

**Risk:** MEDIUM -- folder moves can break Xcode project references
**Mitigation:** Update Xcode project file carefully; verify build immediately after moves
**Claude safe:** YES -- but must update .xcodeproj group references

---

## PR-15: Rename Common/ to SharedUI/

**Goal:** Clarify shared UI boundary with proper naming.

**Approach:** Rename folder, update Xcode project references.

**Files moved:**
- `SmartGames/Common/UI/*` -> `SmartGames/SharedUI/`
- `SmartGames/Common/Components/PrimaryButton.swift` -> `SmartGames/SharedUI/`

**Files deleted:**
- `SmartGames/Common/` (empty after moves)

**Acceptance criteria:**
- [ ] No file in `Common/` folder remains
- [ ] All `AppColors`, `AppFonts`, `AppTheme`, `PrimaryButton` references resolve
- [ ] `BoardTheme` stays in SharedUI for now (moved to Sudoku in PR-17)
- [ ] App compiles and runs

**Risk:** LOW -- pure rename, no logic changes
**Claude safe:** YES

---

## PR-16: Move Sudoku-Specific Services into Games/Sudoku/

**Goal:** Services that are Sudoku-only move out of SharedServices.

**Approach:** Move files, update imports, have SudokuGameModule own these services.

**Files moved:**
- `SharedServices/Statistics/StatisticsService.swift` -> `Games/Sudoku/Services/SudokuStatisticsService.swift`
- `SharedServices/DailyChallenge/DailyChallengeService.swift` -> `Games/Sudoku/Services/`
- `SharedServices/Theme/ThemeService.swift` -> `Games/Sudoku/Services/`
- `SharedServices/Settings/ThemePickerView.swift` -> `Games/Sudoku/Views/`
- `SharedServices/Analytics/AnalyticsEvent+Sudoku.swift` -> `Games/Sudoku/`

**Files modified:**
- `SmartGames/AppEnvironment.swift` -- remove statisticsService, dailyChallengeService, themeService
- `SmartGames/SmartGamesApp.swift` -- remove corresponding environmentObject injections
- `SmartGames/Games/Sudoku/SudokuGameModule.swift` -- create and own these services
- Sudoku views -- update service access pattern

**Acceptance criteria:**
- [ ] AppEnvironment has only truly shared services (7 instead of 11)
- [ ] Sudoku views still access their services (via SudokuGameModule injection)
- [ ] SharedServices/ contains only cross-game services
- [ ] No functionality regression
- [ ] App compiles and runs

**Risk:** HIGH -- most invasive PR; changes service wiring across many Sudoku views
**Mitigation:** Do in sub-steps: move one service at a time, compile between each
**Claude safe:** YES -- with constraint: compile after each file move

---

## PR-17: Move BoardTheme to Sudoku + Create Core/ Folder

**Goal:** Final cleanup: BoardTheme to Sudoku, create Core/ with router/protocol.

**Approach:** Move remaining coupled files to correct modules.

**Files moved:**
- `SmartGames/SharedUI/BoardTheme.swift` -> `SmartGames/Games/Sudoku/Models/`
- `SmartGames/Navigation/AppRouter.swift` -> `SmartGames/Core/`
- `SmartGames/Navigation/AppRoutes.swift` -> `SmartGames/Core/`

**Files deleted:**
- `SmartGames/Navigation/` (empty after moves)
- Old deprecated AppRoute cases (if any remain)

**Acceptance criteria:**
- [ ] `Navigation/` folder removed
- [ ] `Core/` contains GameModule, GameRegistry, AppRouter, AppRoute
- [ ] BoardTheme accessible only to Sudoku
- [ ] App compiles and runs
- [ ] Folder structure matches Phase 2 design

**Risk:** LOW -- pure file moves, no logic changes
**Claude safe:** YES

---

## PR-18: Clean Up EnvironmentObject Injection

**Goal:** Simplify SmartGamesApp from 11 environmentObjects to minimal set.

**Approach:** Views access services through `AppEnvironment` directly instead of individual `@EnvironmentObject` per service. Game-specific services injected by game module's view builders.

**Files modified:**
- `SmartGamesApp.swift` -- reduce to `.environmentObject(environment)` + `.environmentObject(environment.gameRegistry)`
- `ContentView.swift` -- access services via `environment.persistence` etc.
- `HubView.swift` -- update to use `@EnvironmentObject var environment: AppEnvironment`
- `SettingsView.swift` -- same pattern
- Sudoku views -- already handled in PR-16

**Acceptance criteria:**
- [ ] SmartGamesApp injects max 3 environmentObjects
- [ ] All views still access needed services
- [ ] No functionality regression
- [ ] App compiles and runs

**Risk:** MEDIUM -- many view files touched
**Mitigation:** Can be done incrementally (one view at a time)
**Claude safe:** YES -- mechanical find-and-replace pattern

---

## PR-19 (Future): Convert Folder Modules to Local Swift Packages

**Goal:** Build-time isolation and explicit dependency enforcement.

**Approach:** Create `Package.swift` for SharedUI, SharedServices, Core, FeatureGameHub, FeatureSudoku. Add as local packages in Xcode project.

**Deferred until:** Game #2 development begins. Folder modules are sufficient for 1 game.

**Risk:** MEDIUM -- Swift package resolution, resource bundles, preview compatibility
**Claude safe:** NO -- requires manual Xcode project configuration

---

## Migration Order Summary

| PR | Title | Risk | Effort | Claude Safe |
|----|-------|------|--------|-------------|
| 11 | GameModule protocol + GameRegistry | LOW | 1h | YES |
| 12 | SudokuGameModule conformance | LOW | 1h | YES |
| 13 | Refactor AppRoute for dynamic games | MEDIUM | 2h | YES |
| 14 | Hub uses GameRegistry + folder move | MEDIUM | 1.5h | YES |
| 15 | Rename Common/ to SharedUI/ | LOW | 0.5h | YES |
| 16 | Move Sudoku services to Games/Sudoku/ | HIGH | 2.5h | YES* |
| 17 | BoardTheme to Sudoku + Core/ folder | LOW | 0.5h | YES |
| 18 | Simplify EnvironmentObject injection | MEDIUM | 1.5h | YES |
| 19 | Local Swift packages (future) | MEDIUM | 3h | NO |

*With incremental compile-check constraint
