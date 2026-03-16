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

## Planned Phases

### Phase 5: Multi-Game Content (Q2 2026)
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

### Phase 6: Advanced Monetization (Q3 2026)
A/B testing, personalized ad cadence, premium subscriptions.

**Target:** Optimize ARPU + LTV

**Deliverables:**
- Firebase Remote Config for dynamic monetization params
- A/B testing framework for ad frequency, hint rewards
- Optional premium subscription (ad-free, 2x hints)
- Promotional mechanics (bonus hints on reinstall, event campaigns)
- Detailed monetization analytics dashboard

**Status:** Planning

---

### Phase 7: Social & Engagement (Q4 2026)
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

### Phase 8: Content Expansion (2027)
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

### Phase 4 (Current Release)

| Metric | Target | Status |
|--------|--------|--------|
| Localization coverage | 6 languages | Completed |
| Drop Rush level count | 30 levels | Completed |
| Test coverage (Drop Rush) | >80% | Completed |
| Banner ad fill rate | >85% | Monitoring |
| Interstitial frequency (Drop Rush) | Every 2 levels | Implemented |
| Continue ad CTR | >8% | TBD (monitoring) |

### Next Milestones

**Phase 5 Success Criteria:**
- 3rd game released with 50+ content
- Cross-game analytics parity (same event quality)
- Multi-game hub engagement increases DAU by 25%

**Phase 6 Success Criteria:**
- ARPU increases 15-30% via personalized monetization
- Ad fatigue detected + mitigated via A/B testing
- Retention curve improves at day 7, 14, 30

**Phase 7 Success Criteria:**
- DAU increases 30-50% via social features
- Leaderboard participation >40% of MAU
- Seasonal event completion rate >60%

---

## Technical Debt & Maintenance

### Current (Phase 4)
- ✓ All services properly injected
- ✓ Max file size 200 LOC (modular codebase)
- ✓ Analytics event factories (no hardcoded strings)
- ✓ Persistence keys enum-based (no magic strings)
- ✓ AdMob stubs ready for real SDK integration
- ✓ Multi-language support (6 languages)
- ✓ ViewModel+Actions pattern for complex state (Drop Rush model)
- ✓ Per-game SFX configs (Sudoku, Drop Rush)
- ⚠ Banner coordinator uses stub (replace with real GADBannerView)
- ⚠ Firebase integration pending (currently os.log only)

### Phase 5+ Considerations
- Evaluate multi-game contest framework (shared state)
- Refactor leaderboard UI for game-agnostic display
- Plan database schema for user profiles, social features
- Prepare push notification templates for seasonal events
- Consider A/B testing framework integration

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
| 2026-03-13 | 4.0 | Drop Rush Phase 06-08 + Sudoku Audio/Localization Phase 09-11 completed; updated roadmap phases 3-8 |
| 2026-03-12 | 2.6 | Added Phase 2.6 Monetization; updated roadmap with Phases 3-6 |
| 2026-02-15 | 2.5 | Documented Phase 2.5 service decoupling |
| 2026-01-30 | 2.0 | Documented Phase 2 analytics + ads |
| 2025-12-10 | 1.0 | Documented Phase 1 foundation |
