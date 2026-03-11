# Phase Implementation Report

## Executed Phase
- Phase: phase-01-dark-mode-themes
- Plan: /Users/manh.le/github-personal/smartgames/plans/260311-0629-phase2-retention-monetization/
- Status: completed

## Files Modified

| File | Action | Notes |
|------|--------|-------|
| `SmartGames/Common/UI/BoardTheme.swift` | CREATE | BoardThemeName enum + BoardTheme struct + 3 static palettes (classic/dark/sepia) |
| `SmartGames/SharedServices/Theme/ThemeService.swift` | CREATE | `@MainActor ObservableObject`, loads/saves BoardThemeName via PersistenceService |
| `SmartGames/SharedServices/Settings/ThemePickerView.swift` | CREATE | Horizontal swatch picker with mini 3x3 board preview per theme |
| `SmartGames/SharedServices/Persistence/PersistenceService.swift` | MODIFY | Added `Keys.appTheme = "app.theme"` |
| `SmartGames/AppEnvironment.swift` | MODIFY | Added `let theme: ThemeService` init from persistence |
| `SmartGames/SmartGamesApp.swift` | MODIFY | Injected `.environmentObject(environment.theme)` |
| `SmartGames/Common/UI/AppColors.swift` | MODIFY | `appCard`, `appTextPrimary`, `appTextSecondary` now use `UIColor` system colors (auto dark mode) |
| `SmartGames/SharedServices/Settings/SettingsView.swift` | MODIFY | Added "Board Theme" section with `ThemePickerView` |
| `SmartGames/Games/Sudoku/Views/SudokuCellView.swift` | MODIFY | `@EnvironmentObject ThemeService`; all cell colors from `theme.current` |
| `SmartGames/Games/Sudoku/Views/SudokuBoardView.swift` | MODIFY | Board background + grid line colors from theme; `BoardGridLinesView` takes colors as params |
| `SmartGames/Games/Sudoku/Views/SudokuNumberPadView.swift` | MODIFY | Button bg/text from `theme.current.numberPadButton/numberPadText` |
| `SmartGames/Games/Sudoku/Views/SudokuLobbyView.swift` | MODIFY | `Color.white` → `Color.appCard` in resume card + difficulty sheet |
| `SmartGames/Games/Sudoku/Views/SudokuWinView.swift` | MODIFY | `Color.white` → `Color.appCard` |
| `SmartGames/Games/Sudoku/Views/SudokuGameView.swift` | MODIFY | `Color.white` → `Color.appCard` in lost overlay |

## Tasks Completed

- [x] Create `BoardTheme.swift` with 3 palettes (classic/dark/sepia)
- [x] Create `ThemeService.swift` — `@MainActor ObservableObject` with persistence
- [x] Add `PersistenceService.Keys.appTheme`
- [x] Wire `ThemeService` into `AppEnvironment` and `SmartGamesApp`
- [x] Update `SudokuCellView` — all cell colors from `BoardTheme`
- [x] Update `SudokuBoardView` — board background + grid line colors from `BoardTheme`
- [x] Update `SudokuNumberPadView` — button colors from `BoardTheme`
- [x] Update `SudokuLobbyView` — removed hardcoded `Color.white`
- [x] Update `SudokuWinView` — removed hardcoded `Color.white`
- [x] Update `SudokuGameView` lost overlay — removed hardcoded `Color.white`
- [x] Create `ThemePickerView` with mini-grid previews + checkmark on selected
- [x] Add "Board Theme" section to `SettingsView`
- [x] Update `AppColors` — `appCard`, `appTextPrimary`, `appTextSecondary` use `UIColor` system colors for auto dark mode
- [x] Run `xcodegen generate` after creating new files
- [x] Build verified: `** BUILD SUCCEEDED **`

## Tests Status
- Type check: pass (build succeeded with no errors)
- Unit tests: not run (no new test targets configured in project)
- Integration tests: not run
- Manual verification: build clean on iOS Simulator 26.2 (iPhone 17 Pro)

## Issues Encountered

1. **`AppEnvironment` already modified by parallel agent** — by the time this agent edited it, a parallel phase had already added `StatisticsService`. The linter auto-merged both changes cleanly; no conflict.
2. **`SudokuGameView` init signature changed** — a parallel agent added `statisticsService:` param to `SudokuGameViewModel`. Read the updated file before editing to avoid conflict.
3. **`SudokuLobbyView` toolbar changed** — parallel agent added statistics navigation. Read-then-edit pattern handled correctly.
4. **`xcode-select` not pointing to Xcode.app** — worked around via `DEVELOPER_DIR` env var; build succeeded without sudo.
5. **`xcodebuild` device name** — iPhone 16 not installed; used iPhone 17 Pro.

## Unresolved Questions

- `SudokuPauseOverlayView` and `SudokuToolbarView` still use system/app-level colors; not in scope of this phase's ownership but may need theme pass in a follow-up.
- No snapshot tests implemented — manual visual verification required for WCAG AA contrast on Dark/Sepia themes.
- Theme switching animation: `@Published` change on `ThemeService` triggers SwiftUI re-render; flicker has not been measured on device.
