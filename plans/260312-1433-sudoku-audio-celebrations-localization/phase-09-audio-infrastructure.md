# Phase 09 — Audio Infrastructure

**PR:** PR-11
**Priority:** High
**Status:** Completed
**Depends on:** Phase 02 (SoundService exists)

## Overview

Extend the existing `SoundService` and `SettingsService` to support:
1. Background music (looping, per-game configurable)
2. Separate settings toggles for music vs. sound effects
3. App lifecycle pause/resume handling for music
4. Cell-selection sound wired to Sudoku cell tap
5. Additional SFX slots: subgrid completion, puzzle completion

Architecture must remain game-agnostic — future games supply their own audio config through `GameModule`, not hardcoded in shared services.

---

## Architecture

### Ownership

| Concern | Owner | Rationale |
|---------|-------|-----------|
| AVAudioSession, AVAudioPlayer management | `SoundService` (shared) | All games share one audio engine |
| Music file name, SFX file names | `AudioConfig` (per-game struct) | Each game picks its own assets |
| Enable/disable toggles | `SettingsService` (shared) | Cross-game user preference |
| Wiring SFX to game events | Game ViewModel (Sudoku-specific) | Game logic owns when to fire |

### `AudioConfig` Protocol (new, shared)

```swift
/// Each game provides its own AudioConfig. SoundService is agnostic to game logic.
protocol AudioConfig {
    var backgroundMusicFileName: String? { get }  // nil = no music for this game
    var cellTapSFX: String? { get }
    var subgridCompleteSFX: String? { get }
    var puzzleCompleteSFX: String? { get }
}
```

### `SudokuAudioConfig` (new, Sudoku-specific)

```swift
struct SudokuAudioConfig: AudioConfig {
    var backgroundMusicFileName: String? = "sudoku-ambient.mp3"
    var cellTapSFX: String?              = "tap.caf"
    var subgridCompleteSFX: String?      = "subgrid-complete.caf"
    var puzzleCompleteSFX: String?       = "win.caf"
}
```

### `GameModule` protocol extension

Add `var audioConfig: (any AudioConfig)? { get }` to `GameModule`. Default `nil` (opt-in).

### `SoundService` extensions

New methods:
- `startBackgroundMusic(fileName:)` — loads, loops, respects `isMusicEnabled`
- `stopBackgroundMusic()` — fades out gracefully
- `pauseBackgroundMusic()` — on app background
- `resumeBackgroundMusic()` — on app foreground
- `play(_ sfx: String?)` — replaces hardcoded play methods; nil-safe

Existing `play(.tap)`, `play(.win)` etc. become internal aliases; external callers use the new method.

### `SettingsService` additions

```swift
@Published var isMusicEnabled: Bool   // default: true (first launch)
@Published var isSoundEnabled: Bool   // already exists; rename semantics = SFX only
```

Persistence keys:
- `app.settings.musicEnabled`
- `app.settings.soundEnabled` (already exists)

### App Lifecycle

In `SmartGamesApp` / `ScenePhase` observer:
```swift
.onChange(of: scenePhase) { phase in
    switch phase {
    case .background, .inactive: soundService.pauseBackgroundMusic()
    case .active:                soundService.resumeBackgroundMusic()
    }
}
```

### Default Behavior (First Launch)

- Music: **on** by default (warm, welcoming first experience)
- SFX: **on** by default (already the case)
- If user has never opened settings, no prompt — silent defaults

---

## Settings UI Changes

**File:** `SettingsView.swift` — Audio section (new)

```
▸ Audio
  Music           [toggle]
  Sound Effects   [toggle]
  Haptics         [toggle]   ← move here from Gameplay
```

Remove haptics from Gameplay section; consolidate all audio/feel controls in one Audio section.

---

## Related Files

### Modify
- `SmartGames/SharedServices/Settings/SettingsService.swift` — add `isMusicEnabled`
- `SmartGames/SharedServices/Sound/SoundService.swift` — add music + generic SFX play
- `SmartGames/SharedServices/Settings/SettingsView.swift` — Audio section
- `SmartGames/SmartGamesApp.swift` — lifecycle observer for music pause/resume
- `SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift` — wire cell-tap SFX

### Create
- `SmartGames/SharedServices/Sound/AudioConfig.swift` — protocol definition
- `SmartGames/Games/Sudoku/Services/SudokuAudioConfig.swift` — Sudoku audio asset map
- `SmartGames/Games/Sudoku/SudokuModule.swift` — add `audioConfig` property

### Assets
- `sudoku-ambient.mp3` — looping ambient track (calm, minimal, puzzle-appropriate)
- `subgrid-complete.caf` — short positive chime (~0.3s)
- `puzzle-complete.caf` — satisfying resolution sound (~1.5s); can reuse or replace `win.caf`

---

## Analytics Events (new)

Add to `AnalyticsEvent+Settings.swift` (create if not exists):
```swift
static func musicToggled(enabled: Bool) -> AnalyticsEvent
static func soundEffectsToggled(enabled: Bool) -> AnalyticsEvent
```

---

## Persistence

| Key | Type | Default |
|-----|------|---------|
| `app.settings.musicEnabled` | Bool | true |
| `app.settings.soundEnabled` | Bool | true (already) |

---

## Acceptance Criteria

- [ ] Background music starts when Sudoku game screen appears
- [ ] Music pauses when app goes to background; resumes on foreground
- [ ] Music stops when game is paused; resumes when unpaused
- [ ] Music toggle in Settings immediately pauses/resumes music
- [ ] SFX toggle in Settings silences all sound effects immediately
- [ ] Cell tap fires `cellTapSFX` (subtle, not annoying on rapid taps)
- [ ] Tapping rapidly does not stack/delay audio (debounce or interrupt)
- [ ] Future games can pass `nil` for `backgroundMusicFileName` to opt out
- [ ] No music plays in other app screens (Hub, Settings)

## Tests

- `SoundServiceTests`: music play/pause/stop, nil-safe SFX, settings-gated behavior
- `SettingsServiceTests`: `isMusicEnabled` persistence and default
- Manual: background/foreground cycle, Settings toggle mid-game
