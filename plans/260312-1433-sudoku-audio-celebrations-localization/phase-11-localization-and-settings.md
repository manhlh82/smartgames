# Phase 11 — Localization & Settings Language Support

**PR:** PR-13
**Priority:** Medium
**Status:** Completed
**Depends on:** Phase 02 (SettingsService, SettingsView exist)

## Overview

Add multi-language support to the app with an in-app language picker in Settings. Architecture must be game-agnostic — all games benefit automatically as long as they use the shared localization strings system.

---

## Language Strategy

### Follow System vs. Override

**Decision: Follow system by default; allow in-app override.**

- On first launch: use `Locale.current` (device language) — no prompt, no friction
- If user picks a language in Settings: override via `Bundle` swizzle or `UserDefaults["AppleLanguages"]`
- Rationale: most iOS users expect system language to apply automatically; power users (e.g. learners) want manual override

### Implementation Approach

Use **Bundle swizzle** (standard iOS pattern) — no third-party dependency needed:
1. Store selected language code in `UserDefaults["app.settings.languageCode"]` (nil = system)
2. On app launch, if a stored code exists, swap the main bundle's localizations path
3. `LocalizationService` (new, shared) wraps this — view models never call `Bundle.main` directly

```swift
// Usage in views:
Text(LocalizedString("settings.title"))
// or via SwiftUI standard:
Text("settings.title")  // works automatically once bundle is swapped
```

### Recommended Phase 1 Language Set

**Launch with 6 languages** (covers ~3.5B speakers of target casual puzzle demographics):

| Code | Language | Rationale |
|------|----------|-----------|
| `en` | English | Default, base strings |
| `vi` | Vietnamese | Developer market, strong mobile gaming |
| `es` | Spanish | 500M+ speakers, large App Store market |
| `ja` | Japanese | High ARPU iOS market, puzzle game fans |
| `zh-Hans` | Simplified Chinese | Largest mobile market |
| `pt-BR` | Portuguese (Brazil) | Large casual gaming market |

**Defer to Phase 2:** French, German, Korean, Traditional Chinese. These can be added by adding `.lproj` folders and strings — zero code changes.

**Why not all 10 at launch?**
- Translation cost and QA effort scales with each language
- 6 covers highest-value markets; others add incrementally
- Architecture supports adding them without code changes

---

## Architecture

### `LocalizationService` (new, shared)

```swift
/// Manages in-app language override. All games use SwiftUI's standard Text() — no game-specific wiring needed.
final class LocalizationService: ObservableObject {
    @Published var currentLanguageCode: String?   // nil = system
    func setLanguage(_ code: String?)             // persists + triggers bundle swap
    func availableLanguages() -> [AppLanguage]    // list shown in Settings picker
    var displayName: String                       // e.g. "English", "Tiếng Việt"
}

struct AppLanguage: Identifiable {
    let code: String        // BCP-47 e.g. "en", "vi", "ja", "zh-Hans"
    let displayName: String // in the language itself, e.g. "日本語"
    let englishName: String // for fallback display
}
```

`LocalizationService` is added to `AppEnvironment`. It does **not** go in `SudokuGameModule` — it is app-wide.

### String Organization

```
SmartGames/
└── Resources/
    └── Localizations/
        ├── en.lproj/
        │   └── Localizable.strings
        ├── vi.lproj/
        │   └── Localizable.strings
        ├── es.lproj/
        │   └── Localizable.strings
        ├── ja.lproj/
        │   └── Localizable.strings
        ├── zh-Hans.lproj/
        │   └── Localizable.strings
        └── pt-BR.lproj/
            └── Localizable.strings
```

Key naming convention: `{screen}.{component}.{element}` — e.g.:
- `settings.audio.music` → "Music"
- `sudoku.toolbar.hint` → "Hint"
- `hub.title` → "SmartGames"

**No game-specific `.lproj` folders.** All strings in shared `Localizable.strings`. Future games add their keys to the same file — no per-game string resources needed unless strings count grows large enough to warrant splitting (defer that decision).

### Fallback Behavior

- Missing key in selected language → fall back to `en` automatically (Apple's default NSLocalizedString behavior)
- Missing `en` key → display key name (visible bug, caught by tests)
- Language code not supported → silently use system language

### Bundle Swap Timing

Language change takes effect **on next app launch** OR immediately if using `@AppStorage` + `Bundle.localizedBundle` pattern. **Decision: immediate effect** using the bundle swizzle approach — avoids "restart required" friction.

---

## Settings UI Changes

**File:** `SettingsView.swift`

Add Language section:

```
▸ Language
  App Language    [English ▸]   ← NavigationLink to language picker
```

**LanguagePickerView** (new):
- List of `AppLanguage` with checkmark on selected
- "System Default" as first row (code = nil)
- Language names shown in their own language (e.g. "Español", "日本語")
- English name shown as subtitle for clarity

---

## `SettingsService` Changes

`LocalizationService` owns language persistence — do not add language to `SettingsService`. This keeps `SettingsService` focused on gameplay preferences and avoids merging concerns.

---

## Analytics Events

Add to `AnalyticsEvent+Settings.swift`:

```swift
static func languageChanged(from: String?, to: String) -> AnalyticsEvent
// from: previous code or "system", to: new code
```

---

## Persistence

| Key | Type | Default | Owner |
|-----|------|---------|-------|
| `app.settings.languageCode` | String? | nil (system) | `LocalizationService` |

---

## Future Game Extensibility

- New game adds its strings to `Localizable.strings` with its own key prefix (e.g. `chess.board.title`)
- No architecture changes needed — `LocalizationService` is already app-wide
- Each new language supported = add one `.lproj` folder per language
- SwiftUI `Text("key")` works everywhere automatically once bundle is configured

---

## Related Files

### Modify
- `SmartGames/SharedServices/Settings/SettingsView.swift` — Language section + LanguagePickerView
- `SmartGames/SmartGamesApp.swift` — inject `LocalizationService` into environment
- `SmartGames/SharedServices/AppEnvironment.swift` — add `localizationService`

### Create
- `SmartGames/SharedServices/Localization/LocalizationService.swift`
- `SmartGames/SharedServices/Localization/AppLanguage.swift`
- `SmartGames/SharedServices/Settings/LanguagePickerView.swift`
- `SmartGames/Resources/Localizations/en.lproj/Localizable.strings` (base)
- `SmartGames/Resources/Localizations/vi.lproj/Localizable.strings`
- `SmartGames/Resources/Localizations/es.lproj/Localizable.strings`
- `SmartGames/Resources/Localizations/ja.lproj/Localizable.strings`
- `SmartGames/Resources/Localizations/zh-Hans.lproj/Localizable.strings`
- `SmartGames/Resources/Localizations/pt-BR.lproj/Localizable.strings`

---

## Acceptance Criteria

- [ ] Settings shows Language row; tap opens picker with 6 languages + "System Default"
- [ ] Selecting a language immediately updates all visible text without restart
- [ ] Selected language persists across app launches
- [ ] Language names shown in their own script (e.g. "日本語" not "Japanese")
- [ ] "System Default" resets to device language
- [ ] Missing translation key falls back to English (no crash, no empty text)
- [ ] Future language added by adding `.lproj` folder only — zero code changes
- [ ] Analytics fires on language change
- [ ] All existing Sudoku UI strings have entries in `en.lproj/Localizable.strings`

## Tests

- `LocalizationServiceTests`: language persistence, fallback behavior, nil = system default
- Manual: switch to Japanese mid-game — all UI strings switch; switch back — restored
- String audit: grep for hardcoded English strings not using `NSLocalizedString` / `Text("key")` pattern
