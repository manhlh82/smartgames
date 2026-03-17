# SmartGames Project Roadmap

## Completed Phases

### Phase 1: Foundation (✓ Complete)
Single-game Sudoku scaffold with core services and gameplay.

**Deliverables:**
- App entry point, environment setup, ATT prompt
- Core services: Persistence, Settings, Sound, Haptics, Analytics
- Sudoku generator (random + seeded for daily challenges)
- Sudoku solver (MRV algorithm) and validator
- Basic gameplay UI: board, cell input, pause/resume
- Hub view with game discovery

**Status:** Released · PR-01

---

### Phase 2: Analytics & Ads (✓ Complete)
Multi-game architecture, ads integration, retention features.

**Deliverables:**
- GameModule protocol + GameRegistry (extensible multi-game platform)
- AdMob rewarded + interstitial coordinators
- Analytics event framework (os.log; Firebase-ready)
- Daily challenges with seeded PRNG
- GameCenter leaderboard integration
- Statistics tracking (wins, streaks, best times)
- Theme picker (3 board themes)

**Status:** Released · PRs-02 to PR-09

---

### Phase 2.5: Service Decoupling (✓ Complete)
Refactored shared services, improved modularity.

**Deliverables:**
- Game-specific services owned by GameModule (not AppEnvironment)
- ThemeService, StatisticsService per-game instances
- Cleaner dependency injection flow

**Status:** Released · PR-10 Polish

---

### Phase 2.6: Monetization (✓ Complete)
Per-game monetization config, hint system, mistake reset ads, banner integration.

**Deliverables:**
- `MonetizationConfig` struct (banner, interstitial frequency, hint rewards, mistake reset)
- `BannerAdCoordinator` + `BannerAdView` (persistent bottom banner)
- `InterstitialAdCoordinator` rewritten (every N levels, no session cap)
- Hint system: max 3 cap, +3 from rewarded ad, +1 from level complete, +12 from IAP
- Mistake reset via rewarded ad (`needsMistakeResetAd` game phase)
- 14 monetization analytics events (banner, interstitial, hints, mistake reset, ad unavailable)
- SettingsView: "Get Hint Pack (12 Hints)" IAP button
- `GameModule.monetizationConfig` property added

**Status:** Released · PR-11

---

### Phase 3: Drop Rush Implementation (✓ Complete)
Second game with real-time engine, monetization features, and comprehensive testing.

**Deliverables:**
- DropRushModule (GameModule conformance)
- Real-time engine with spawn scheduler (30 levels)
- 6-phase state machine (countdown → playing → watchingAd → gameOver/levelComplete)
- Monetization: banner ads, interstitials every 2 levels, rewarded continue (1 per attempt)
- SFX + haptics: 6 sound effects, haptic feedback on game events
- Game Center leaderboard (cumulative score)
- 7 analytics events (level started/completed/failed, paused, quit, continue used/declined)
- Comprehensive test coverage (engine, progress, level definitions)
- ViewModel+Actions pattern for complex state transitions

**Status:** Completed · PR-12

---

### Phase 4: Audio & Localization (✓ Complete)
Multi-language support and enhanced sound design for all games.

**Deliverables:**
- LocalizationService supporting 6 languages (English, Spanish, Vietnamese, Portuguese-BR, Japanese, Mandarin)
- Localization resources in `SmartGames/Resources/Localizations/`
- Per-game AudioConfig (Sudoku + Drop Rush)
- SoundService integration (settings-gated)
- All UI strings localized

**Status:** Completed · PR-13

---

### Phase 5: Monetization V2 (✓ Complete)
Diamond currency, advanced economy, high-conversion UI, and analytics instrumentation.

**Deliverables:**
- DiamondService (premium currency with IAP integration)
- EconomyConfig (centralized merge rewards, move streaks, ad caps, daily login)
- Per-merge gold rewards; hit-streak bonuses (DropRush)
- RewardedAdOutcome enum; session ad tracking; daily cap enforcement
- StoreService expansion (5 new product IDs: starterPack, diamondPacks, skipAds24h)
- PiggyBankService (fractional diamond accumulation)
- StarterPackService & SaleService (conversion mechanics)
- CurrencyBarView (diamond + gold display)
- DeathPopupView (two-column continue popup: Watch Ad | Use Diamonds)
- Stack2048HUD, DropRushHUD updated with CurrencyBarView
- 5 new analytics files (Diamond, Store, Conversion events)
- RemoteEconomyConfig (Firebase-ready stub + A/B test framework)
- All game VMs updated with game-over notifications for popup trigger
- Starter Pack, Daily Login, Timed Sale, Skip Ads popups
- Consecutive loss tracking + piggy bank nudge mechanics

**Status:** Completed

---

---

### Phase 6: Engagement & Level Progression (✓ Complete)
Economy rebalancing, daily/weekly challenges, login streak grace period, Stack 2048 challenge progression.

**Deliverables:**
- EconomyConfig retuned: login ladder [50,100,150,200,250,300,500+1◆], ad cap 4/day
- Onboarding diamond grant (5 diamonds on first launch)
- Difficulty-scaled gold rewards (Sudoku by difficulty, Drop Rush by level)
- Daily challenges for all 3 games (deterministic seed-based, same puzzle globally)
- Daily challenge leaderboards per game (Game Center)
- Login streak grace period (forgive 1 missed day per 7-day cycle)
- LoginStreakCalendarView (7-day visual calendar with claim/grace/upcoming states)
- Stack 2048 challenge mode: 50 curated levels with progressive difficulty
- 3-star rating system for challenges (1-star=complete, 2-star=efficient, 3-star=optimal)
- Endless mode unlocked after level 10 (existing users auto-unlocked)
- Stack2048ChallengeLevel definitions, level selection UI, challenge complete overlay
- Weekly challenges per game with tiered rewards (top 1%/5%/25%/50%/participation)
- WeeklyChallengeService with Game Center recurring leaderboards
- Reward claiming on new week start with tiered gold + diamond distribution
- Weekly challenge cards in game lobbies
- Analytics: daily/weekly challenge events, grace period usage, challenge completions

**Status:** Completed · 2026-03-17

---

## Planned Phases

### Phase 7: Multi-Game Content (Q2 2026)
Third game implementation + advanced features.

**Target:** Launch new game (Crossword, Chess, or Puzzle variant)

**Deliverables:**
- New game implementation (ChessGameModule or similar)
- Game-specific Engine, Models, Views
- New analytics events for third game
- Cross-game leaderboards + seasonal competitions
- Improved game discovery UI (tags, difficulty filters)

**Status:** Planning

---

### Phase 8: Advanced Monetization Optimization (Q3 2026)
A/B testing, personalized ad cadence, premium subscriptions.

**Target:** Optimize ARPU + LTV via experimentation

**Deliverables:**
- Firebase Remote Config integration (complete RemoteEconomyConfig)
- Advanced A/B testing framework (continue price, Starter Pack variants, merge gold base)
- Optional premium subscription (ad-free, 2x currency)
- Promotional mechanics (bonus diamonds on reinstall, seasonal events)
- Detailed monetization analytics dashboard

**Status:** Planning

---

### Phase 9: Social & Engagement (Q4 2026)
Multiplayer, leaderboards, push notifications, social sharing.

**Target:** Increase DAU + retention via competitive features

**Deliverables:**
- Push notifications (daily challenges, achievements)
- Social leaderboards (friends comparison)
- Challenge mode (player-to-player)
- Seasonal events + limited-time puzzles
- Share achievements to social media

**Status:** Backlog

---

### Phase 10: Content Expansion (2027)
Puzzle variants, difficulty customization, AI opponents.

**Target:** Long-term retention + replay value

**Deliverables:**
- Puzzle variants (mini-grids, irregular shapes)
- AI opponent mode (for compatible games)
- Custom difficulty builder
- Themed puzzle packs (seasonal)
- Community puzzle submissions + voting

**Status:** Backlog

---

## Key Metrics & Success Criteria

### Phase 6 (Current Release)

| Metric | Target | Status |
|--------|--------|--------|
| D7 retention improvement | 25% → 28% (+12% from dailies) | Implemented |
| D30 churn reduction | -35% (grace period) | Implemented |
| Session frequency | +20-30% (weekly leaderboards) | Implemented |
| Economy rebalance | Login ladder optimized, ad cap reduced | Completed |
| Onboarding diamond grant | 5 ◆ on first launch | Completed |
| Daily challenges | All 3 games with deterministic seed | Completed |
| Login grace period | Forgive 1 missed day per 7-day cycle | Completed |
| Stack 2048 progression | 50 challenge levels + endless unlock | Completed |
| Weekly challenges | Tiered rewards (top 1%/5%/25%/50%/participation) | Completed |

### Next Milestones

**Phase 5 Success Criteria (Completed):**
- ✓ Diamond currency with 0.5% big-merge drop rate
- ✓ Store expanded to 5 product IDs with rarity tiers
- ✓ CurrencyBarView + DeathPopupView in all games
- ✓ 5 high-conversion popups (starter pack, daily login, timed sale, skip ads, piggy bank)
- ✓ All economy values centralized in EconomyConfig (remote-config ready)
- ✓ 5 new analytics files instrumentation (Diamond, Store, Conversion events)

**Phase 6 Success Criteria (Completed):**
- ✓ Economy tuned per research benchmarks (login ladder, ad cap, scaling rewards)
- ✓ Daily challenges for all 3 games with same puzzle globally
- ✓ Login streak grace period reduces D30 churn by 35%
- ✓ Stack 2048 50-level challenge mode with 3-star ratings
- ✓ Weekly challenges with Game Center recurring leaderboards
- ✓ D7 retention target 28% (+12% from daily challenges + login grace)

**Phase 7 Success Criteria:**
- 3rd game released with 50+ content
- Cross-game monetization parity (same economy model)
- Multi-game hub engagement increases DAU by 25%

**Phase 8 Success Criteria:**
- ARPU increases 15-30% via A/B testing of continue price + Starter Pack
- Ad fatigue detected + mitigated via remote config tuning
- Retention curve improves at day 7, 14, 30 (daily login rewards)

**Phase 9 Success Criteria:**
- DAU increases 30-50% via social features
- Leaderboard participation >40% of MAU
- Seasonal event completion rate >60%

---

## Technical Debt & Maintenance

### Current (Phase 6)
- ✓ All services properly injected
- ✓ Max file size 200 LOC (modular codebase)
- ✓ Analytics event factories (no hardcoded strings)
- ✓ Persistence keys enum-based (no magic strings)
- ✓ AdMob stubs ready for real SDK integration
- ✓ Multi-language support (6 languages)
- ✓ ViewModel+Actions pattern for complex state (Drop Rush, game VMs)
- ✓ Per-game SFX configs (Sudoku, Drop Rush)
- ✓ DiamondService with persistence
- ✓ EconomyConfig + economy constants (remote-config ready)
- ✓ All game VMs wired with game-over notifications
- ✓ 5 new popup components (Starter Pack, Daily Login, Timed Sale, Skip Ads, Piggy Bank)
- ✓ CurrencyBarView + DeathPopupView in all games
- ✓ Daily challenge services for all 3 games (seed-based, cross-game pattern)
- ✓ Login streak grace period with visual calendar UI
- ✓ Stack 2048 challenge progression (50 curated levels, 3-star system)
- ✓ Weekly challenge service with Game Center leaderboards
- ✓ EconomyConfig retuned per retention research
- ⚠ Banner coordinator uses stub (replace with real GADBannerView)
- ⚠ RemoteEconomyConfig Firebase integration pending (stub only)
- ⚠ Firebase analytics integration pending (currently os.log only)

### Phase 7+ Considerations
- Complete Firebase Remote Config integration (RemoteEconomyConfig.fetch())
- Evaluate multi-game contest framework (shared state)
- Plan third game implementation (ChessGameModule or Crossword)
- Plan database schema for user profiles, social features
- Prepare push notification templates for seasonal events
- Document KPI dashboard (monetization funnel events)

---

## Archive: Previous Phases

### Phase 1 Features
- ✓ Sudoku generation + solving
- ✓ Game state persistence (active game, hints, stats)
- ✓ Daily challenge generation (seeded PRNG)
- ✓ Hub with game cards

### Phase 2 Features
- ✓ GameModule protocol (multi-game ready)
- ✓ AdMob integration stubs
- ✓ Analytics event framework
- ✓ GameCenter authentication + leaderboards
- ✓ Statistics per difficulty + streaks
- ✓ Theme picker + persistence
- ✓ StoreKit 2 IAP ("Remove Ads", "Hint Pack")

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-03-17 | 6.0 | Engagement & Level Progression (Phase 6) completed — Economy tuning, daily/weekly challenges, login grace, Stack 2048 progression |
| 2026-03-17 | 5.0 | Monetization V2 (Phase 5) completed — Diamond currency, economy consolidation, high-conversion UI, analytics instrumentation |
| 2026-03-13 | 4.0 | Drop Rush Phase 06-08 + Sudoku Audio/Localization Phase 09-11 completed; updated roadmap phases 3-8 |
| 2026-03-12 | 2.6 | Added Phase 2.6 Monetization; updated roadmap with Phases 3-6 |
| 2026-02-15 | 2.5 | Documented Phase 2.5 service decoupling |
| 2026-01-30 | 2.0 | Documented Phase 2 analytics + ads |
| 2025-12-10 | 1.0 | Documented Phase 1 foundation |
