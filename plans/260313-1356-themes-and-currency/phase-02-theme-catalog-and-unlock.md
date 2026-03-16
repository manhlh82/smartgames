# Phase 2: Theme Catalog & Unlock

## Context Links

- [Plan overview](plan.md)
- [Phase 1: Currency](phase-01-currency-model-and-rewards.md)
- [BoardTheme.swift](../../SmartGames/Common/UI/BoardTheme.swift)
- [ThemeService.swift](../../SmartGames/SharedServices/Theme/ThemeService.swift)

## Overview

- **Priority:** P1
- **Status:** completed
- **Description:** Expand `BoardThemeName` to 9 themes, define color palettes, add unlock state to `ThemeService`, implement purchase flow.

## Key Insights

- `BoardThemeName` is an enum with `CaseIterable` -- adding cases auto-populates pickers.
- `ThemeService` already owns theme selection and persistence. Adding unlock tracking here keeps cohesion.
- Existing themes: classic (Light), dark, sepia. Rename/remap: `classic` stays as free "Light", `dark` stays free, `sepia` becomes "Brownish Calm" (paid). Add 6 new paid themes.
- `ThemeService` is currently Sudoku-specific (owned by `SudokuGameModule`). To make it shared, move ownership to `AppEnvironment`. This is a breaking change but necessary for cross-game themes.

## Architecture

### Updated BoardThemeName

```swift
enum BoardThemeName: String, Codable, CaseIterable, Identifiable {
    case light       // FREE (was "classic")
    case dark        // FREE
    case cherry
    case brownishCalm  // was "sepia"
    case highContrast
    case yellowPaper
    case nature
    case cityscapes
    case snowy

    var id: String { rawValue }

    var displayName: String { ... }

    var isFree: Bool {
        self == .light || self == .dark
    }

    var price: Int {
        switch self {
        case .light, .dark: return 0
        case .cherry, .brownishCalm, .highContrast, .yellowPaper: return 50
        case .nature, .cityscapes: return 75
        case .snowy: return 100
        }
    }
}
```

**Migration note:** Old persisted value `"classic"` maps to nothing after rename. Handle in `ThemeService.init`: if loaded name is nil or unrecognized, default to `.light`. Add backward compat: decode `"classic"` -> `.light`, `"sepia"` -> `.brownishCalm`.

### Color Palettes (all 9)

Defined as `static let` on `BoardTheme`:

| Theme | Board BG | Cell BG | Cell Text | Given Text | Accent/Selected | Grid |
|-------|----------|---------|-----------|-----------|-----------------|------|
| **Light** | #F5F5F5 | #FFFFFF | #007AFF | #1C1C1E | #1565C0 | #333333 |
| **Dark** | #1C1C1E | #2C2C2E | #64B5F6 | #E0E0E0 | #42A5F5 | #AAAAAA |
| **Cherry** | #2D0A0A | #3D1515 | #FF6B6B | #FFD4D4 | #E53935 | #8B3A3A |
| **Brownish Calm** | #F5E6D3 | #FFF8F0 | #795548 | #4E342E | #A1887F | #8D6E63 |
| **High Contrast** | #000000 | #FFFFFF | #000000 | #000000 | #FFD600 | #000000 |
| **Yellow Paper** | #FFF8E1 | #FFFDE7 | #5D4037 | #3E2723 | #F9A825 | #8D6E63 |
| **Nature** | #1B3A1B | #2E4E2E | #81C784 | #C8E6C9 | #43A047 | #4C7A4C |
| **Cityscapes** | #1A1A2E | #252545 | #7FAADC | #C5CAE9 | #5C6BC0 | #3F3F6F |
| **Snowy** | #E8EAF6 | #F5F5FF | #37474F | #263238 | #42A5F5 | #90A4AE |

Full `BoardTheme` properties (15 colors each) derived from these base tones. Keep existing pattern of explicit hex values for every property.

### ThemeService Changes

```swift
@MainActor
final class ThemeService: ObservableObject {
    @Published private(set) var current: BoardTheme
    @Published var themeName: BoardThemeName { didSet { ... } }
    @Published private(set) var unlockedThemes: Set<BoardThemeName>

    private let persistence: PersistenceService
    private let currencyService: CurrencyService

    init(persistence: PersistenceService, currencyService: CurrencyService)

    /// Returns true if theme is free or has been purchased.
    func isUnlocked(_ name: BoardThemeName) -> Bool

    /// Attempt purchase. Returns false if already unlocked or insufficient funds.
    func purchase(_ name: BoardThemeName) -> Bool

    func setTheme(_ name: BoardThemeName)  // guard: only if unlocked
}
```

### Persistence Keys

```swift
static let unlockedThemes = "app.themes.unlocked"  // Set<String> (rawValues)
```

### Analytics

```swift
static func themePurchased(theme: String, price: Int, balanceAfter: Int) -> AnalyticsEvent
static func themeSelected(theme: String) -> AnalyticsEvent
static func themePurchaseFailed(theme: String, reason: String) -> AnalyticsEvent
```

Add to `AnalyticsEvent+Currency.swift` (theme purchases are currency events).

## Related Code Files

### Modify

| File | Change |
|------|--------|
| `SmartGames/Common/UI/BoardTheme.swift` | Rename `classic`->`light`, `sepia`->`brownishCalm`, add 6 new cases + palettes, add `isFree`/`price` |
| `SmartGames/SharedServices/Theme/ThemeService.swift` | Add `unlockedThemes`, `purchase()`, `isUnlocked()`, accept `CurrencyService`, backward-compat decoding |
| `SmartGames/SharedServices/Persistence/PersistenceService.swift` | Add `unlockedThemes` key |
| `SmartGames/AppEnvironment.swift` | Move `ThemeService` from `SudokuGameModule` to `AppEnvironment` |
| `SmartGames/Games/Sudoku/SudokuModule.swift` | Remove `themeService` ownership, use `environment.themeService` |
| `SmartGames/Games/Sudoku/Views/*.swift` | No change -- already uses `@EnvironmentObject var themeService` |
| `SmartGames/SharedServices/Analytics/AnalyticsEvent+Currency.swift` | Add theme purchase/select events |

### Create

None (all changes in existing files).

## Implementation Steps

1. **Update `BoardThemeName` enum**
   - Rename `classic` -> `light`, `sepia` -> `brownishCalm`
   - Add cases: `cherry`, `highContrast`, `yellowPaper`, `nature`, `cityscapes`, `snowy`
   - Add `displayName`, `isFree`, `price` computed properties
   - Add `CodingKeys` or custom `init(from:)` to map legacy `"classic"` -> `.light` and `"sepia"` -> `.brownishCalm`

2. **Define 6 new color palettes in `BoardTheme`**
   - Add `static let cherry`, `highContrast`, `yellowPaper`, `nature`, `cityscapes`, `snowy`
   - Update `theme(for:)` switch to handle all 9 cases
   - Rename `static let classic` -> `static let light`, `static let sepia` -> `static let brownishCalm`
   - File will exceed 200 lines -- split into `BoardTheme.swift` (struct + enum) and `BoardThemePalettes.swift` (static palette definitions)

3. **Add persistence key**
   - `static let unlockedThemes = "app.themes.unlocked"` in `PersistenceService.Keys`

4. **Extend `ThemeService`**
   - Add `currencyService: CurrencyService` parameter to init
   - Add `@Published private(set) var unlockedThemes: Set<BoardThemeName>`
   - Load unlocked set from persistence in init; default = `[.light, .dark]`
   - `isUnlocked(_:)`: return `name.isFree || unlockedThemes.contains(name)`
   - `purchase(_:)`:
     ```swift
     guard !isUnlocked(name) else { return false }  // already owned
     guard currencyService.spend(amount: name.price) else { return false }  // insufficient
     unlockedThemes.insert(name)
     saveUnlocked()
     analytics.log(.themePurchased(...))
     return true
     ```
   - `setTheme(_:)`: guard `isUnlocked(name)`, else fallback to `.light`
   - Backward compat: if loaded `themeName` is paid and not in unlocked set, reset to `.light`

5. **Move ThemeService to AppEnvironment**
   - Add `let themeService: ThemeService` to `AppEnvironment`
   - Create in `init()`: `ThemeService(persistence: persistence, currencyService: currency)`
   - Add `.environmentObject(env.themeService)` in `SmartGamesApp`
   - Remove `themeService` property from `SudokuGameModule`
   - Remove `.environmentObject(themeService)` from `SudokuModule.makeLobbyView()` etc. (now injected app-wide)

6. **Add analytics events**
   - `themePurchased`, `themeSelected`, `themePurchaseFailed` in `AnalyticsEvent+Currency.swift`

7. **Compile and verify**

## Todo

- [x] Rename `classic`/`sepia` in `BoardThemeName`, add 6 new cases
- [x] Add backward-compat decoding for legacy theme names
- [x] Define all 9 color palettes (split file if >200 lines)
- [x] Add `unlockedThemes` persistence key
- [x] Add `unlockedThemes`, `purchase()`, `isUnlocked()` to `ThemeService`
- [x] Accept `CurrencyService` in `ThemeService` init
- [x] Move `ThemeService` from `SudokuModule` to `AppEnvironment`
- [x] Add `.environmentObject(env.themeService)` in `SmartGamesApp`
- [x] Remove theme ownership from `SudokuModule`
- [x] Add theme analytics events
- [x] Compile check

## Success Criteria

- All 9 themes render correctly with distinct palettes
- Free themes (light, dark) always accessible
- Paid themes locked by default, purchasable with coins
- `purchase()` deducts coins and persists unlock
- Double-purchase returns `false`, no coins deducted
- Legacy `"classic"` / `"sepia"` persistence values migrate cleanly
- Selected paid theme that becomes "lost" falls back to light

## Edge Cases & Bug Risks

| Risk | Mitigation |
|------|-----------|
| Double-spend on same theme | `purchase()` checks `isUnlocked()` first |
| Legacy persisted `"classic"` value | Custom `init(from:)` maps old rawValues |
| Paid theme selected but unlock lost (reinstall) | `setTheme()` verifies unlock, falls back to `.light` |
| ThemeService move breaks Sudoku injection | All views already use `@EnvironmentObject` -- just need app-level injection |
| File >200 lines after 9 palettes | Split into `BoardTheme.swift` + `BoardThemePalettes.swift` |

## Security / Persistence

- Unlocked themes stored as `Set<String>` in UserDefaults. On reinstall, lost -- user restarts with free themes. Acceptable for MVP (no server sync).
- No way to inject fake unlocks without device access (sandboxed).
