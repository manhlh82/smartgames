# Phase 1: Dark Mode + Board Themes

## Context Links
- [AppTheme.swift](../../SmartGames/Common/UI/AppTheme.swift)
- [AppColors.swift](../../SmartGames/Common/UI/AppColors.swift)
- [SettingsService.swift](../../SmartGames/SharedServices/Settings/SettingsService.swift)
- [SettingsView.swift](../../SmartGames/SharedServices/Settings/SettingsView.swift)
- [SudokuCellView.swift](../../SmartGames/Games/Sudoku/Views/SudokuCellView.swift)
- [SudokuBoardView.swift](../../SmartGames/Games/Sudoku/Views/SudokuBoardView.swift)

## Overview
- **Priority:** P1 -- quickest win, foundation for all other phases
- **Status:** ✅ Complete
- **Effort:** 4h
- **Description:** Add system dark mode support + 3 board themes (Classic, Dark, Sepia). Theme preference persisted via SettingsService. All hardcoded colors replaced with theme-driven values.

## Key Insights
- Current `AppColors.swift` uses hardcoded light-mode hex values (`.appCard = Color.white`, `.appBackground = systemGroupedBackground`)
- `SudokuLobbyView` and `SudokuWinView` use `Color.white` directly -- must be replaced
- `AppTheme.swift` is layout-only (corner radii, padding) -- extend with color scheme
- `SettingsService` already has persistence wired via `SettingsData` Codable struct -- add `selectedTheme` field
- iOS `preferredColorScheme` modifier handles system dark mode override

## Requirements

### Functional
- FR1: App respects system dark/light mode by default
- FR2: User can pick board theme: Classic (default), Dark, Sepia
- FR3: Theme preference persists across launches
- FR4: Board theme affects: board background, cell background, cell text, grid lines, highlight colors
- FR5: Theme picker in Settings with live preview swatch

### Non-Functional
- NFR1: Zero visible flicker on theme switch
- NFR2: WCAG AA contrast ratios for all text on all themes
- NFR3: No new dependencies

## Architecture

### New Files
```
SmartGames/Common/UI/BoardTheme.swift          -- BoardTheme enum + color palettes
SmartGames/Common/UI/ThemeService.swift         -- ObservableObject publishing current BoardTheme
SmartGames/SharedServices/Settings/ThemePickerView.swift -- Theme selector UI component
```

### BoardTheme Enum
```swift
enum BoardThemeName: String, Codable, CaseIterable, Identifiable {
    case classic, dark, sepia
    var id: String { rawValue }
}

struct BoardTheme {
    let name: BoardThemeName
    let boardBackground: Color
    let cellBackground: Color
    let cellText: Color
    let givenText: Color
    let gridLine: Color
    let thickGridLine: Color
    let selectedCell: Color
    let relatedCell: Color
    let sameNumberCell: Color
    let selectedEmptyCell: Color
    let errorCell: Color
    let pencilMarkText: Color
}
```

### ThemeService
```swift
@MainActor
final class ThemeService: ObservableObject {
    @Published var currentTheme: BoardTheme
    @Published var themeName: BoardThemeName { didSet { applyTheme(); save() } }

    private let persistence: PersistenceService
    // Load from persistence, default .classic
}
```

### Color Palettes
| Token | Classic | Dark | Sepia |
|-------|---------|------|-------|
| boardBackground | #F5F5F5 | #1C1C1E | #F5E6D3 |
| cellBackground | #FFFFFF | #2C2C2E | #FFF8F0 |
| cellText | #1C1C1E | #FFFFFF | #3E2723 |
| givenText | #1C1C1E | #E0E0E0 | #4E342E |
| gridLine | #C0C0C0 | #555555 | #D7CCC8 |
| thickGridLine | #333333 | #AAAAAA | #8D6E63 |
| selectedCell | #1565C0 | #42A5F5 | #A1887F |
| relatedCell | #E3F2FD | #1E3A5F | #EFEBE9 |
| sameNumberCell | #B2EBF2 | #1B3B3F | #D7CCC8 |
| errorCell | #FFEBEE | #5C1A1A | #FFCCBC |

## Files to Modify

| File | Change |
|------|--------|
| `Common/UI/AppColors.swift` | Replace hardcoded Sudoku highlight colors with computed properties reading from ThemeService, or deprecate them in favor of BoardTheme |
| `Common/UI/AppTheme.swift` | No change (layout tokens stay) |
| `SharedServices/Settings/SettingsService.swift` | Add `selectedTheme: BoardThemeName` property + persist |
| `SharedServices/Settings/SettingsView.swift` | Add "Board Theme" section with ThemePickerView |
| `AppEnvironment.swift` | Add `ThemeService` property |
| `SmartGamesApp.swift` | Inject `.environmentObject(environment.theme)` |
| `Games/Sudoku/Views/SudokuCellView.swift` | Read theme from environment, use `theme.cellBackground`, `theme.cellText` etc |
| `Games/Sudoku/Views/SudokuBoardView.swift` | Use `theme.boardBackground`, `theme.gridLine` |
| `Games/Sudoku/Views/SudokuLobbyView.swift` | Replace `Color.white` with semantic colors |
| `Games/Sudoku/Views/SudokuWinView.swift` | Replace `Color.white` with semantic colors |
| `Games/Sudoku/Views/SudokuNumberPadView.swift` | Theme number pad buttons |

## Files to Create

| File | Purpose |
|------|---------|
| `Common/UI/BoardTheme.swift` | Theme enum, palette struct, static theme definitions |
| `Common/UI/ThemeService.swift` | Observable theme provider |
| `SharedServices/Settings/ThemePickerView.swift` | Inline theme picker for Settings |

## Implementation Steps

1. **Create `BoardTheme.swift`**
   - Define `BoardThemeName` enum (classic, dark, sepia)
   - Define `BoardTheme` struct with all color tokens
   - Create static factory methods: `BoardTheme.classic`, `.dark`, `.sepia`
   - Add `static func theme(for name: BoardThemeName) -> BoardTheme`

2. **Create `ThemeService.swift`**
   - `@MainActor final class ThemeService: ObservableObject`
   - `@Published var current: BoardTheme`
   - Init loads `BoardThemeName` from PersistenceService, defaults to `.classic`
   - `func setTheme(_ name: BoardThemeName)` -- updates current + saves

3. **Update `SettingsService.swift`**
   - Add `@Published var selectedTheme: BoardThemeName` with didSet saving
   - Add to `SettingsData` codable struct
   - Default to `.classic`

4. **Update `AppEnvironment.swift`**
   - Add `let theme: ThemeService`
   - Init: `self.theme = ThemeService(persistence: persistence)`

5. **Update `SmartGamesApp.swift`**
   - Add `.environmentObject(environment.theme)` to view hierarchy

6. **Update `SudokuCellView.swift`**
   - Add `@EnvironmentObject var theme: ThemeService`
   - Replace all hardcoded colors with `theme.current.xxx`
   - Map `CellHighlightState` to theme colors

7. **Update `SudokuBoardView.swift`**
   - Use `theme.current.boardBackground` for board container
   - Use `theme.current.gridLine` / `thickGridLine` for separators

8. **Update `SudokuNumberPadView.swift`**
   - Theme button text and backgrounds

9. **Update `SudokuLobbyView.swift`**
   - Replace `Color.white` with `Color.appCard` (make `appCard` dynamic)
   - Or use `theme.current.cellBackground` where board-specific

10. **Update `SudokuWinView.swift`**
    - Replace `Color.white` with semantic color

11. **Create `ThemePickerView.swift`**
    - Horizontal scrolling row of 3 theme swatches
    - Each swatch: mini 3x3 grid preview using theme colors
    - Checkmark overlay on selected theme

12. **Update `SettingsView.swift`**
    - Add "Board Theme" section embedding `ThemePickerView`

13. **Update `AppColors.swift`**
    - Make `.appCard`, `.appBackground` respect dark mode via `UIColor.systemBackground`
    - Keep Sudoku-specific colors as fallback but prefer BoardTheme in Sudoku views

## Todo List

- [ ] Create `BoardTheme.swift` with 3 palettes
- [ ] Create `ThemeService.swift`
- [ ] Update `SettingsService` + `SettingsData` with theme field
- [ ] Wire `ThemeService` into `AppEnvironment` and `SmartGamesApp`
- [ ] Update `SudokuCellView` to use theme colors
- [ ] Update `SudokuBoardView` to use theme colors
- [ ] Update `SudokuNumberPadView` to use theme colors
- [ ] Update `SudokuLobbyView` -- remove hardcoded `Color.white`
- [ ] Update `SudokuWinView` -- remove hardcoded `Color.white`
- [ ] Create `ThemePickerView` with mini-grid previews
- [ ] Add theme section to `SettingsView`
- [ ] Update `AppColors` for system dark mode support
- [ ] Verify WCAG AA contrast for all 3 themes
- [ ] Test theme switching with no flicker

## Acceptance Criteria

- [ ] App renders correctly in system light and dark mode
- [ ] User can switch between Classic, Dark, Sepia in Settings
- [ ] Theme persists after kill + relaunch
- [ ] All board elements (cells, grid lines, highlights, number pad) reflect chosen theme
- [ ] No hardcoded `Color.white` remains in Sudoku views
- [ ] Accessibility: all text meets WCAG AA contrast on every theme

## Tests Needed

- `ThemeService`: verify default theme loads as `.classic`
- `ThemeService`: verify theme change persists and reloads correctly
- `BoardTheme`: verify all 3 static palettes have non-nil colors
- `SettingsService`: verify `selectedTheme` round-trips through persistence
- UI: snapshot tests for board in all 3 themes (manual or automated)

## Security Considerations
- None -- purely cosmetic, no network, no user data

## Next Steps
- Phase 2 (Statistics) can proceed in parallel
- Theme system enables future premium themes (Phase 3+ IAP expansion)
