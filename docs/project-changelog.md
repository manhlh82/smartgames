# SmartGames Project Changelog

All significant changes, features, and fixes to the SmartGames iOS app are documented here.

## Version 7.0 — 2026-03-17

### Phase 7: Crossword Game Module + Content Pipeline

**Game Module (CrosswordGameModule)**
- Full MVVM crossword puzzle game with three board sizes (7×7 mini, 9×9 standard, 11×11 extended)
- 12 themed puzzle packs: animals, food, fruits, sports, space, nature, ocean, city, school, travel, weather, music
- Hint system with three hint types: soft hints (category, length, first letter), word reveal, clue reveal
- Daily challenge support with deterministic seed-based puzzle selection
- Save/load game state + statistics tracking per theme/difficulty
- Game Center daily leaderboards per theme
- Pack-based puzzle loading from bundled JSON resources

**Offline Content Pipeline (Python)**
- Word bank builder: 916 words across 12 themes with scoring (popularity, crossword fit, theme fit)
- Clue pipeline: Template-based clue generation with manual override support
- Crossword generator: Seed-based deterministic generation for reproducibility
- Pack builder: 185 total puzzles across 10 packs (18-20 puzzles per pack)
- Validation framework: JSON schema validation + integrity checks
- End-to-end orchestration: `bash scripts/run-pipeline.sh` (all steps, ~2 min)
- 65 Python unit tests (all passing): normalization, scoring, board placement, generator determinism, pack validation
- Comprehensive documentation: README, TROUBLESHOOTING, requirements.txt
- License attribution: `LICENSE_NOTES.md` documenting MIT/Apache/CC0 sources
- Output: `crossword-packs-index.json` + per-pack resource files for iOS bundling

**Analytics Events**
- `crossword_puzzle_started(theme:difficulty:)`, `crossword_puzzle_completed(theme:score:time:)`
- `crossword_hint_used(hintType:)`, `crossword_paused`, `crossword_quit`
- Daily challenge events: `daily_challenge_started(game:)`, `daily_challenge_completed(game:score:stars:streak:)`

**New Files**
- `SmartGames/Games/Crossword/` — game module
- `pipeline/` — Python library (config, models, scoring, generator, pack builder, validation)
- `scripts/` — CLI tools (fetch, build-wordbank, build-clues, generate-pack, validate)
- `tests/` — 65 unit tests covering core pipeline components
- `data/` — source data (raw lists, processed banks, denylist, overrides)
- `outputs/` — generated artifacts (word banks, clues, puzzles, packs)
- `requirements.txt` — Python dependencies (pytest, pydantic)
- `LICENSE_NOTES.md` — source attribution
- `TROUBLESHOOTING.md` — common issues + solutions

**Success Metrics**
- Pipeline generates valid puzzle packs end-to-end in <2 minutes
- All 65 Python tests pass (normalization, scoring, board, generator, pack validation)
- iOS app successfully loads all 185 puzzles from 10 themed packs
- Daily challenge determinism verified (same seed = same puzzle)

---

## Version 6.0 — 2026-03-17

### Phase 6: Engagement & Level Progression

**Economy Tuning**
- Rebalanced login reward ladder: [50, 100, 150, 200, 250, 300, 500] gold + 1 diamond on day 7
- Reduced ad watch daily cap: 5 → 4 ads/day (retention vs ad fatigue optimization)
- Added onboarding diamond grant: 5 diamonds on first launch (demo hard currency value)
- Implemented difficulty-scaled gold rewards:
  - Sudoku: 15g (easy) → 60g (expert)
  - Drop Rush: 10g + (level/10)*5, capped at 50g
  - Stack 2048: score-based (unchanged)
- Centralized economy constants in `EconomyConfig` (remote-config ready via `RemoteEconomyConfig`)

**Daily Challenges for All Games**
- Extended daily challenge system beyond Sudoku to Drop Rush + Stack 2048
- Deterministic seed-based generation: same puzzle for all players globally per day
- Per-game daily challenge services follow same pattern:
  - `DropRushDailyChallengeService` — generates daily level config from UTC date seed
  - `Stack2048DailyChallengeService` — generates daily board state from seed
- Daily challenge leaderboards per game via Game Center: `com.smartgames.{game}.leaderboard.daily`
- Daily completion tracking + streak per game
- Gold rewards: 25g base + 25g bonus for 3-star completion

**Login Streak Grace Period**
- Added "forgiving streak" mechanic: miss 1 day per 7-day cycle without resetting streak
- Grace period configurable: `EconomyConfig.loginStreakMaxGracePerCycle = 1`
- Tracks grace usage per cycle (max 1 use per 7 days, resets on day 7 or streak reset)
- Visual component: `LoginStreakCalendarView` — 7-day calendar showing:
  - Claimed (green checkmark)
  - Graced (yellow exclamation — streak saved via grace)
  - Upcoming (gray)
  - Today (blue ring)
- Integrated into `DailyLoginPopupView`
- Analytics: `daily_login_grace_used(streakDay:)` — track grace utilization

**Stack 2048 Challenge Mode**
- Added 50 numbered challenge levels with progressive difficulty
- Challenge level structure:
  - Levels 1-10: Tutorial-like, easy targets (reach 64 tile)
  - Levels 11-25: Medium (reach 128-256)
  - Levels 26-40: Hard (reach 256-512)
  - Levels 41-50: Expert (reach 512-1024)
- 3-star rating system:
  - 1-star: complete challenge (reach target)
  - 2-star: efficient (complete within N moves)
  - 3-star: optimal (complete within M moves, tighter limit)
- Move limit enforcement per level (nil for 1-star, enforced for 2-3)
- Pre-placed tiles via seed for unique starting positions per level
- Endless mode unlocked after completing level 10
- Existing users auto-unlocked for endless (backward compatible migration)
- Gold rewards: 15g base + 10g per extra star (1-star=15g, 2-star=25g, 3-star=35g)
- New files/models:
  - `Stack2048ChallengeLevel` — level definition struct
  - `Stack2048ChallengeLevelDefinitions` — 50 curated level configs
  - `Stack2048ChallengeLevelSelectView` — level grid with star ratings
  - `Stack2048ChallengeCompleteOverlay` — star result screen
- Extended `Stack2048Progress` with `challengeStars: [Int: Int]` and `endlessUnlocked: Bool`
- Updated `Stack2048GameViewModel` with challenge mode support
- Updated `Stack2048LobbyView` with mode selection (Challenge/Endless)

**Weekly Challenges & Leaderboards**
- New `WeeklyChallengeService` for cross-game weekly challenge coordination
- Weekly leaderboards per game (Monday-Sunday cycle) via Game Center:
  - `com.smartgames.sudoku.leaderboard.weekly`
  - `com.smartgames.dropRush.leaderboard.weekly`
  - `com.smartgames.stack2048.leaderboard.weekly`
- Best score during week auto-submitted to Game Center
- Tiered reward system based on leaderboard rank:
  - Top 1%: 500g + 3 diamonds
  - Top 5%: 300g + 1 diamond
  - Top 25%: 150g
  - Top 50%: 50g
  - Participation: 25g (if ≥1 game played)
- Rewards claimed on app launch Monday (or new week start)
- Weekly challenge card in each game's lobby showing current rank + "View Leaderboard" button
- `WeeklyChallengeResultView` popup — shows rank achieved, reward tier, gold/diamond earned on new week
- All game ViewModels updated to submit score to weekly challenge service on completion
- Analytics: `weekly_challenge_reward_claimed(game:tier:gold:diamonds:)`
- New files:
  - `WeeklyChallengeService` — week tracking, reward claiming
  - `WeeklyChallengeModels` — state, tier enums, reward configs
  - `WeeklyChallengeCardView` — lobby card component
  - `WeeklyChallengeResultView` — popup for reward display

**Analytics & Events**
- Daily challenge events: `daily_challenge_started(game:)`, `daily_challenge_completed(game:score:stars:streak:)`
- Weekly challenge event: `weekly_challenge_reward_claimed(game:tier:gold:diamonds:)`
- Grace period event: `daily_login_grace_used(streakDay:)`
- Challenge mode events: `stack2048_challenge_started(level:)`, `stack2048_challenge_completed(level:stars:moves:)`

**Other Improvements**
- `AppEnvironment` now includes `onboardingDiamondGranted` tracking
- Added `DailyLeaderboardID` constants to `GameCenterService`
- Cross-game economy parity enforced (same reward structure for comparable activities)

**Success Metrics**
- Target D7 retention: 25% → 28% (+12% from daily challenges + login grace)
- Target D30 churn reduction: -35% (grace period per Forrester research)
- Target session frequency: +20-30% (weekly leaderboards)

---

## Version 5.0 — 2026-03-17

### Phase 5: Monetization V2

**Dual Currency System**
- DiamondService for premium currency (hard currency)
- GoldService for soft currency (abundant, merge-based)
- 0.5% big-merge drop rate for diamonds (tie-in to game mechanics)
- Diamond persistence via `PersistenceService`

**Economy Consolidation**
- Centralized `EconomyConfig` with all economy constants
- `RemoteEconomyConfig` stub for Firebase remote configuration + A/B testing
- Per-merge gold rewards based on tile value
- Hit-streak bonuses for consecutive merges (Drop Rush)
- Daily ad watch cap enforcement via `AdRewardTracker`

**Store Expansion**
- StoreKit 2 integration with 5 product IDs:
  1. Remove Ads ($2.99)
  2. Hint Pack ($0.99)
  3. Starter Pack ($4.99) — 50 diamonds + exclusive theme
  4. Diamond Packs (5 SKUs: $0.99 → $99.99)
  5. Skip Ads 24h ($1.99)
- `StoreService` for product fetching + transaction handling
- Rarity indicators on store items (common/uncommon/rare/epic)

**High-Conversion UI Components**
- `CurrencyBarView` — top bar displaying diamond (bright) + gold (subdued) balance
- `DeathPopupView` — two-column continue popup: "Watch Ad" vs "2 Diamonds"
- `StarterPackPopupView` — full-screen overlay: "50 ◆ + Exclusive Theme"
- `DailyLoginPopupView` — 7-day reward display with streak tracking
- `TimedSalePopupView` — limited-time diamond sale with countdown timer
- `SkipAdsBannerView` — non-intrusive "Skip ads" banner
- `PiggyBankView` — fractional diamond accumulation display
- All popups integrated into game VMs via notification system

**Service Enhancements**
- `DailyLoginRewardService` — tracks login streak, grants daily gold + diamonds
- `PiggyBankService` — accumulates fractional diamonds from merges
- `StarterPackService` — first-session offer state management
- `SaleService` — timed sale countdown + expiry management
- Game-over notification system in all 3 game VMs for popup triggering

**Analytics Instrumentation**
- 5 new analytics event files:
  - `AnalyticsEvent+Diamond` — earn/spend, drop roll tracking
  - `AnalyticsEvent+Store` — purchase funnel (impression → start → complete)
  - `AnalyticsEvent+Conversion` — CTA impression + tap events
  - Integrated 20+ monetization events into analytics pipeline
- Event factories (no hardcoded strings)
- Funnel tracking for store, starter pack, death popup, timed sale

**Game Integration**
- All game VMs wired with game-over notifications
- Currency bar display in all games (Sudoku, Drop Rush, Stack 2048)
- Death popup for death continuation flow
- Reward granting on completion (gold + diamonds)

---

## Version 4.0 — 2026-03-13

### Drop Rush Phases 06-08 + Sudoku Audio/Localization

**Drop Rush Enhancements**
- 30 playable levels with progressive difficulty
- Pause/resume functionality
- Level-based progression tracking
- Difficulty-scaled rewards

**Sudoku Audio & Localization**
- 6-language support (English, Spanish, Vietnamese, Portuguese-BR, Japanese, Mandarin)
- Per-game audio configuration
- Sound event system (taps, completions, errors, wins)
- Haptic feedback integration

---

## Version 2.6 — 2026-03-12

### Phase 2.6: Monetization

**Initial Monetization Framework**
- MonetizationConfig per game
- BannerAdCoordinator + BannerAdView
- InterstitialAdCoordinator rewritten
- Hint system (max 3 cap, +3 from rewarded ad, +1 from level complete, +12 from IAP)
- Mistake reset via rewarded ad
- 14 monetization analytics events
- SettingsView IAP button for Hint Pack

---

## Version 2.5 — 2026-02-15

### Phase 2.5: Service Decoupling

**Architecture Improvements**
- Game-specific services owned by GameModule (not AppEnvironment)
- ThemeService, StatisticsService per-game instances
- Cleaner dependency injection flow

---

## Version 2.0 — 2026-01-30

### Phase 2: Analytics & Ads

**Multi-Game Architecture**
- GameModule protocol for extensible game implementation
- GameRegistry for game discovery
- 3 games registered: Sudoku, Drop Rush, Stack 2048

**AdMob Integration**
- Rewarded ad coordinator
- Interstitial ad coordinator
- Session-based ad tracking

**Analytics Framework**
- os.log based event logging
- Firebase-ready event structure
- 20+ custom events

**Daily Challenges**
- Seeded PRNG for deterministic puzzles
- Sudoku daily challenge implementation
- Cross-game pattern ready

**Game Center**
- Player authentication
- Leaderboard integration
- Per-game leaderboards

**Extended Features**
- Statistics tracking (wins, streaks, best times)
- Theme picker (3 board themes with persistence)

---

## Version 1.0 — 2025-12-10

### Phase 1: Foundation

**Core Infrastructure**
- App entry point + environment setup
- ATT (App Tracking Transparency) prompt
- Core services: Persistence, Settings, Sound, Haptics, Analytics
- AppEnvironment dependency injection container
- NavigationPath router

**Sudoku Implementation**
- Sudoku generator (random + seeded for daily)
- Sudoku solver (MRV algorithm) + uniqueness check
- Puzzle validator + hint system
- Daily challenge generation
- Per-difficulty statistics
- Board themes (Classic, Dark, Sepia)
- 7-phase game state machine

**UI & Views**
- Hub/Home screen with game discovery
- Sudoku gameplay screen
- Board view (9×9 grid with Canvas lines)
- Cell view (6 highlight states)
- Statistics display screen
- Theme picker UI
- Settings screen

**Persistence & Services**
- UserDefaults-backed PersistenceService
- JSON-safe serialization
- Game state persistence (active game, hints, stats)

---

## Notes on Release Process

- All phases are independently deployable
- Backward compatibility maintained across version upgrades
- Remote configuration planned for future phases (Firebase integration)
- Analytics data used to drive iteration and optimization decisions

---

## Future Changelog Entries

Significant changes will be logged here following the format:
- Feature additions → "Added"
- Bug fixes → "Fixed"
- Breaking changes → "Changed" (with migration notes)
- Deprecated features → "Deprecated" (with sunset timeline)
- Security fixes → "Security" (with severity level)
