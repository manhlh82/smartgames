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
| `Views/DailyChallengeView.swift` | Daily challenge play screen (seed-based, same puzzle globally) |
| `Models/SudokuDailyChallengeModels.swift` | SudokuDailyChallengeState, SudokuDailyStreakData |
| `Services/SudokuDailyChallengeService.swift` | Daily challenge generation + streak tracking (Phase 2, extended Phase 6 for multi-game daily pattern) |
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
| `Services/DropRushDailyChallengeService.swift` | Daily challenge generation from seed, completion tracking, streak management (Phase 6) |
| `Models/DropRushDailyChallengeModels.swift` | DropRushDailyChallengeState, DropRushDailyStreakData (Phase 6) |
| `Views/DropRushDailyChallengeView.swift` | Daily challenge entry screen showing today's challenge, streak, completion status (Phase 6) |

**Analytics Events:**
- `drop_rush_level_started`, `drop_rush_level_completed`, `drop_rush_level_failed`
- `drop_rush_paused`, `drop_rush_quit`
- `drop_rush_continue_used`, `drop_rush_continue_declined`
- `daily_challenge_started(game:)`, `daily_challenge_completed(game:score:stars:streak:)` (Phase 6)
- `weekly_challenge_reward_claimed(game:tier:gold:diamonds:)` (Phase 6)

**Game Center:**
- Leaderboard: com.smartgames.dropRush.leaderboard.cumulative (cumulative score)
- Leaderboard: com.smartgames.dropRush.leaderboard.daily (daily challenge score) (Phase 6)
- Leaderboard: com.smartgames.dropRush.leaderboard.weekly (weekly challenge score) (Phase 6)

## Crossword Game Module

Registered via `CrosswordGameModule` conforming to `GameModule` protocol.

**Crossword is a standard word puzzle game:**
- 7×7 (mini), 9×9 (standard), 11×11 (extended) board sizes
- 12 themed puzzle packs (animals, food, fruits, sports, space, nature, ocean, city, school, travel, weather, music)
- 185 total puzzles (seed-based generation for reproducibility)
- Daily challenge support (seeded puzzle selection)
- Hint system + soft hints (category, length, first letter)
- Save/load game state + statistics tracking

| File | Purpose |
|------|---------|
| `CrosswordGameModule.swift` | Implements GameModule contract |
| `Models/CrosswordPuzzle.swift` | Puzzle model (theme, difficulty, packId, softHints) |
| `Models/CrosswordPack.swift` | Pack metadata (title, theme, difficulty, puzzleCount) |
| `Models/CrosswordBoardState.swift` | In-game board state + solved tracking |
| `Engine/CrosswordPuzzleBank.swift` | Pack-based puzzle loading + daily challenge |
| `Engine/CrosswordValidator.swift` | Word validation, win detection, hint logic |
| `ViewModels/CrosswordGameViewModel.swift` | Game state machine (playing → paused → won/lost); hint management |
| `Views/CrosswordGameView.swift` | Main gameplay screen with grid + clues |
| `Views/CrosswordLobbyView.swift` | Theme/pack selection + pack preview |
| `Views/CrosswordGridView.swift` | Interactive word grid with cell selection |
| `Views/CrosswordClueView.swift` | Across/down clue list |
| `Services/CrosswordDailyChallengeService.swift` | Daily challenge generation from seed |
| `Models/CrosswordDailyChallengeModels.swift` | DailyChallengeState, StreakData |

**Analytics Events:**
- `crossword_puzzle_started(theme:difficulty:)`, `crossword_puzzle_completed(theme:score:time:)`
- `crossword_hint_used(hintType:)`, `crossword_paused`, `crossword_quit`
- `daily_challenge_started(game:)`, `daily_challenge_completed(game:score:stars:streak:)` (Phase 6)

**Resources:**
- `SmartGames/Games/Crossword/Resources/crossword-packs-index.json` — pack manifest
- `SmartGames/Games/Crossword/Resources/crossword-pack-*.json` — individual puzzle packs (5 puzzles each, embedded)

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
| `Views/Stack2048LobbyView.swift` | Lobby with best score stats + mode selection (Challenge/Endless) + Play button |
| `Models/Stack2048ChallengeLevel.swift` | Level definition struct: targetTile, targetScore, moveLimit, initialTiles, starThresholds |
| `Services/Stack2048ChallengeLevelDefinitions.swift` | 50 curated challenge level configurations |
| `Views/Stack2048ChallengeLevelSelectView.swift` | Level grid (5 cols × 10 rows) with star ratings + locked/unlocked states |
| `Views/Stack2048ChallengeCompleteOverlay.swift` | Challenge completion screen: stars earned, gold earned, "Next Level"/"Retry" buttons |

**Analytics Events:**
- `stack2048_game_started`, `stack2048_game_over`
- `stack2048_milestone_tile` (512, 1024, 2048, 4096)
- `stack2048_power_up_used`, `stack2048_paused`, `stack2048_quit`
- `stack2048_challenge_started(level:)`, `stack2048_challenge_completed(level:stars:moves:)` (Phase 6)

| `Services/Stack2048DailyChallengeService.swift` | Daily challenge generation from seed, completion tracking, streak management (Phase 6) |
| `Models/Stack2048DailyChallengeModels.swift` | Stack2048DailyChallengeState, Stack2048DailyStreakData (Phase 6) |
| `Views/Stack2048DailyChallengeView.swift` | Daily challenge entry screen showing today's challenge, streak, completion status (Phase 6) |

**Persistence Key:** `stack2048.progress` (extended with `challengeStars: [Int: Int]`, `endlessUnlocked: Bool`)

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
| `DailyChallengeService` | Sudoku daily challenge (seeded) | Shared |
| `GameCenterService` | GKLocalPlayer auth, leaderboards (daily + weekly + cumulative) | Shared |
| `GoldService` | Gold currency (per-merge, streaks, daily login, difficulty-scaled) | Shared |
| `DiamondService` | Diamond premium currency (IAP + drops + onboarding grant) | Shared |
| `StoreService` | StoreKit 2, IAP (5 product IDs) | Shared |
| `GameRegistry` | Game module registration | Shared |
| `EconomyConfig` | Centralized economy constants (retuned, remote-config ready) | Shared |
| `RemoteEconomyConfig` | Remote economy overrides + A/B test variants | Shared |
| `AdRewardTracker` | Daily ad-watch cap enforcement (5→4) | Shared |
| `DailyLoginRewardService` | Login streak + grace period + daily rewards | Shared |
| `PiggyBankService` | Fractional diamond accumulation | Shared |
| `StarterPackService` | First-session offer state | Shared |
| `SaleService` | Timed sale expiry management | Shared |
| `DropRushDailyChallengeService` | Drop Rush daily challenge (seed-based level generation) | Shared |
| `Stack2048DailyChallengeService` | Stack 2048 daily challenge (seed-based board generation) | Shared |
| `WeeklyChallengeService` | Weekly leaderboard scores, tiered rewards claiming | Shared |

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

## New Shared Components (Phase 6 — Engagement & Level Progression)

| Component | Purpose |
|-----------|---------|
| `LoginStreakCalendarView.swift` | 7-day visual calendar: claimed (✓ green), graced (! yellow), upcoming (gray), today (blue ring) |
| `WeeklyChallengeCardView.swift` | Lobby card showing current week's best score + rank + "View Leaderboard" button |
| `WeeklyChallengeResultView.swift` | Popup displayed on new week start: rank achieved, reward tier, gold/diamonds earned |

## Monetization Files Added

| File | Purpose |
|------|---------|
| `AnalyticsEvent+Diamond.swift` | Diamond earn/spend events + drop roll tracking |
| `AnalyticsEvent+Store.swift` | Purchase funnel (impression → start → complete) |
| `AnalyticsEvent+Conversion.swift` | CTA impression + tap events (starter pack, death popup, timed sale) |

## Analytics Files Added (Phase 6)

| File | Purpose |
|------|---------|
| `AnalyticsEvent+DailyChallenge.swift` | Daily challenge started/completed/failed per game, streak tracking |
| `AnalyticsEvent+WeeklyChallenge.swift` | Weekly challenge reward claimed with tier + currency amounts |
| `AnalyticsEvent+LoginStreak.swift` | Grace period usage tracking |
| `AnalyticsEvent+Stack2048Challenge.swift` | Challenge level started/completed with stars + move count |

## Crossword Content Pipeline

Offline Python pipeline that generates themed puzzle packs for the Crossword game module.

| Directory | Purpose |
|-----------|---------|
| `pipeline/` | Python library (config, models, scoring, generator, pack builder, schema validation) |
| `scripts/` | Executable Python scripts (fetch wordlists, build word banks, generate clues, build packs, validate) |
| `tests/` | Python unit tests (65 tests, all passing; normalization, scoring, board, generator, pack validation) |
| `data/` | Source data (raw word lists, processed banks, denylist, allowlist, clue overrides) |
| `outputs/` | Generated artifacts (word banks, clues, individual puzzles, packs, sample files) |

**Key Files:**
- `scripts/run-pipeline.sh` — end-to-end orchestration (7 steps, ~2 min runtime)
- `scripts/build-wordbank.py` — 916 words across 12 themes with scoring
- `scripts/build-clues.py` — template-based clue generation with quality checks
- `scripts/generate-pack.py` — 10 packs, 185 total puzzles (7×7, 9×9, 11×11)
- `scripts/validate-outputs.py` — JSON schema validation + integrity checks
- `requirements.txt` — pytest, pydantic (minimal dependencies)
- `LICENSE_NOTES.md` — source attribution (MIT/Apache/CC0 licensed sources)
- `TROUBLESHOOTING.md` — common issues + solutions

**Output:**
- 10 puzzle packs (1 pack per theme, 18-20 puzzles/pack)
- Pack index: `crossword-packs-index.json` (metadata)
- Individual packs: `crossword-pack-{theme}.json` (puzzles embedded)
- Copied to `SmartGames/Games/Crossword/Resources/` for iOS bundling

## PR History

01 scaffold · 02 services · 03 hub · 04 engine · 05-07 gameplay · 08 ads · 09 analytics · 10 polish · 11 monetization · 12 drop-rush-phases-06-07-08 · 13 sudoku-audio-localization-phases-09-10-11 · 14-20 monetization-v2-phases-01-07 · 21-28 engagement-level-progression-phases-01-06 · 29-36 crossword-game-and-pipeline
