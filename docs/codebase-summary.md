# Codebase Summary

## Architecture

MVVM + EnvironmentObject. All services injected at root via `AppEnvironment`.

## Key Files

| File | Purpose |
|------|---------|
| `SmartGamesApp.swift` | App entry, env injection, ATT |
| `AppEnvironment.swift` | Central DI container; wires shared & game modules |
| `Core/GameModule.swift` | Protocol defining game module contract |
| `Core/GameRegistry.swift` | Holds all registered game modules |
| `Navigation/AppRouter.swift` | NavigationPath router |
| `Hub/HubViewModel.swift` | Reads games from GameRegistry |

## Sudoku Game Module

Registered via `SudokuGameModule` conforming to `GameModule` protocol.

**Sudoku owns:**
- `ThemeService` — Board themes (persisted via SettingsService)
- `StatisticsService` — Per-difficulty stats (persisted via PersistenceService)

| File | Purpose |
|------|---------|
| `SudokuGameModule.swift` | Implements GameModule contract; owns theme + stats services; provides monetizationConfig |
| `Engine/SudokuGenerator.swift` | Random/seeded backtracking generation |
| `Engine/SudokuSolver.swift` | MRV solver + uniqueness check |
| `Engine/SudokuValidator.swift` | Move validation, hint, win check |
| `Engine/PuzzleBank.swift` | JSON puzzle pool + played tracking |
| `Engine/SeededRandomNumberGenerator.swift` | xorshift64 PRNG for deterministic daily puzzles |
| `ViewModels/SudokuGameViewModel.swift` | 7-phase game state machine; manages hints, mistake resets |
| `Views/SudokuGameView.swift` | Main gameplay screen; integrates BannerAdView + CurrencyBarView + monetization overlays |
| `Views/SudokuBoardView.swift` | 9x9 grid + Canvas lines |
| `Views/SudokuCellView.swift` | Cell with 6 highlight states |
| `Views/SudokuStatisticsView.swift` | Per-difficulty stats screen |
| `Views/SudokuStatsCardsGrid.swift` | Stats metric cards (win rate, streaks, times) |
| `Views/DailyChallengeView.swift` | Daily challenge play screen |
| `Views/PaywallView.swift` | Tabbed store (Gold Items + Premium ◆); rarity indicators; piggy bank |
| `Views/ThemePickerView.swift` | Board theme selector with rarity borders + exclusive badges |
| `Views/SettingsView.swift` | App settings; "Get Hint Pack" IAP button |

## Drop Rush Game Module

Registered via `DropRushModule` conforming to `GameModule` protocol.

**Drop Rush owns:**
- Game engine, level definitions, and state management
- Per-level progression tracking

| File | Purpose |
|------|---------|
| `DropRushModule.swift` | Implements GameModule contract; provides monetizationConfig |
| `Engine/DropRushEngine.swift` | Core game loop (spawn, collision, scoring) |
| `Engine/SpawnScheduler.swift` | Object spawn timing + wave logic |
| `Engine/LevelDefinitions.swift` | 30 level configs (difficulty, spawn rates, object pools) |
| `Models/LevelConfig.swift` | Level parameters (symbols, speeds, target accuracy) |
| `Models/DropRushGameState.swift` | Game state (score, lives, objects, accuracy) |
| `Models/DropRushStats.swift` | Per-level stats (wins, best scores, high score) |
| `Models/FallingObject.swift` | Object physics + rendering |
| `ViewModels/DropRushGameViewModel.swift` | 6-phase state machine (countdown → playing → levelComplete/gameOver); merge gold, move streaks, consecutive loss tracking, game-over notification |
| `ViewModels/DropRushGameViewModel+Actions.swift` | `requestContinue()` with rewarded ad flow (1 continue per attempt) |
| `Services/DropRushAudioConfig.swift` | SFX definitions (dropRush-hit, dropRush-wrong, dropRush-miss, dropRush-speedup, dropRush-level-complete, dropRush-gameover) |
| `Views/DropRushGameView.swift` | Main gameplay screen; watchingAd overlay integration |
| `Views/DropRushLobbyView.swift` | Level selection + banner ad |
| `Views/DropRushResultOverlay.swift` | Level end screen; "Watch Ad to Continue" button |
| `Views/DropRushHUDView.swift` | Score, lives, accuracy display |
| `Views/DropRushInputBarView.swift` | Cell input buttons |
| `Views/DropRushPauseOverlay.swift` | Pause menu with resume/quit options |

**Analytics Events:**
- `drop_rush_level_started`, `drop_rush_level_completed`, `drop_rush_level_failed`
- `drop_rush_paused`, `drop_rush_quit`
- `drop_rush_continue_used`, `drop_rush_continue_declined`

**Game Center:**
- Leaderboard: com.smartgames.dropRush.leaderboard.cumulative (cumulative score)

## Stack 2048 Game Module

Registered via `Stack2048Module` conforming to `GameModule` protocol.

**Stack 2048 is an endless merge puzzle:**
- 5 columns × 10 rows grid; tiles stack top-to-bottom (newest at top)
- Drop tiles into columns; same-value tiles chain-merge (2048-style doubling)
- Power-ups: Hammer (destroy tile, 150 Gold), Shuffle (new tile, 200 Gold)
- Rewarded ad: +100 Gold; game over = all columns full

| File | Purpose |
|------|---------|
| `Stack2048Module.swift` | Implements GameModule contract |
| `Engine/Stack2048Engine.swift` | Pure-logic engine: dropTile, chain-merge, hammer, shuffle |
| `Models/Stack2048Tile.swift` | Tile model (value, id, merge animation flag) |
| `Models/Stack2048GameState.swift` | State snapshot + EngineEvent enum |
| `Models/Stack2048Progress.swift` | Persisted progress (high score, best tile, games played) |
| `ViewModels/Stack2048GameViewModel.swift` | 5-phase state machine (playing/paused/hammerMode/watchingAd/gameOver); merge gold, hit-streak bonus, game-over notification |
| `Services/Stack2048AudioConfig.swift` | Audio config (no BGM; SFX played by name) |
| `Views/Stack2048Colors.swift` | Tile color scheme (2→sky blue … 2048→gold) |
| `Views/Stack2048TileView.swift` | Tile with merge pulse animation |
| `Views/Stack2048BoardView.swift` | 5-column grid; column-tap + hammer tile-tap |
| `Views/Stack2048HUDView.swift` | Gold balance, score, high score, pause |
| `Views/Stack2048ControlBarView.swift` | Hammer, Shuffle, next tile display, Ad button |
| `Views/Stack2048PauseOverlay.swift` | Pause menu |
| `Views/Stack2048GameOverOverlay.swift` | Game over with score, gold earned, retry |
| `Views/Stack2048GameView.swift` | Main gameplay screen with all overlays |
| `Views/Stack2048LobbyView.swift` | Lobby with best score stats + Play button |

**Analytics Events:**
- `stack2048_game_started`, `stack2048_game_over`
- `stack2048_milestone_tile` (512, 1024, 2048, 4096)
- `stack2048_power_up_used`, `stack2048_paused`, `stack2048_quit`

**Persistence Key:** `stack2048.progress`

## Shared Cross-Game Services (AppEnvironment)

| Service | Purpose | Scope |
|---------|---------|-------|
| `PersistenceService` | UserDefaults+JSON, Keys enum | Shared |
| `SettingsService` | App-wide settings (persisted) | Shared |
| `SoundService` | AVAudioPlayer, settings-gated | Shared |
| `HapticsService` | UIFeedbackGenerator, settings-gated | Shared |
| `AdsService` | AdMob rewarded + interstitial, session tracking | Shared |
| `BannerAdCoordinator` | Banner ad lifecycle management | Shared |
| `AnalyticsService` | Event logging (20+ monetization events) | Shared |
| `DailyChallengeService` | Cross-game daily feature | Shared |
| `GameCenterService` | GKLocalPlayer auth, leaderboards | Shared |
| `GoldService` | Gold currency (per-merge, streaks, daily login) | Shared |
| `DiamondService` | Diamond premium currency (IAP + drops) | Shared |
| `StoreService` | StoreKit 2, IAP (5 product IDs) | Shared |
| `GameRegistry` | Game module registration | Shared |
| `EconomyConfig` | Centralized economy constants (remote-config ready) | Shared |
| `RemoteEconomyConfig` | Remote economy overrides + A/B test variants | Shared |
| `AdRewardTracker` | Daily ad-watch cap enforcement | Shared |
| `DailyLoginRewardService` | Login streak + daily rewards | Shared |
| `PiggyBankService` | Fractional diamond accumulation | Shared |
| `StarterPackService` | First-session offer state | Shared |
| `SaleService` | Timed sale expiry management | Shared |

## Game-Specific Services (Inside GameModule)

**Sudoku** owns its own:
- `ThemeService` — Board themes (Classic/Dark/Sepia)
- `StatisticsService` — Per-difficulty stats

## Game State Machine

```
playing ↔ paused
playing → won | lost | needsHintAd | needsMistakeResetAd
```

## Persistence Keys

- `sudoku.activeGame` — SudokuGameState
- `sudoku.hints.remaining` — Int
- `sudoku.playedPuzzleIDs` — Set<String>
- `sudoku.stats.{difficulty}` — SudokuStats
- `app.settings` — SettingsData

## Localization & Audio

**Localization (Sudoku + Drop Rush):**
- Languages: English, Spanish, Vietnamese, Portuguese (Brazil), Japanese, Chinese (Simplified)
- Service: `LocalizationService` + `AppLanguage` enum
- Resources: `SmartGames/Resources/Localizations/` (one .lproj per language)

**Audio Configuration:**
- Service: `SoundService` (settings-gated)
- Game configs: `SudokuAudioConfig.swift`, `DropRushAudioConfig.swift`
- Events trigger SFX playback (taps, completions, errors, speedups, game-overs)

## New Shared Components (Phase 5 — Monetization V2)

| Component | Purpose |
|-----------|---------|
| `CurrencyBarView.swift` | Top bar displaying diamond (bright/cyan) + gold (subdued) balance |
| `DeathPopupView.swift` | Two-column continue popup: Watch Ad (left) vs 2 Diamonds (right) |
| `StarterPackPopupView.swift` | Full-screen overlay: "50 ◆ + Exclusive Theme" offer |
| `DailyLoginPopupView.swift` | 7-day calendar strip with streak tracking + reward animation |
| `TimedSalePopupView.swift` | Bottom sheet with countdown timer (1h limited-time diamond sale) |
| `SkipAdsBannerView.swift` | Reusable non-intrusive banner: "Skip ads ◆ 2/session" or "Remove all ads $2.99" |

## Monetization Files Added

| File | Purpose |
|------|---------|
| `AnalyticsEvent+Diamond.swift` | Diamond earn/spend events + drop roll tracking |
| `AnalyticsEvent+Store.swift` | Purchase funnel (impression → start → complete) |
| `AnalyticsEvent+Conversion.swift` | CTA impression + tap events (starter pack, death popup, timed sale) |

## PR History

01 scaffold · 02 services · 03 hub · 04 engine · 05-07 gameplay · 08 ads · 09 analytics · 10 polish · 11 monetization · 12 drop-rush-phases-06-07-08 · 13 sudoku-audio-localization-phases-09-10-11 · 14+ monetization-v2-phases-01-07
