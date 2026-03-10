# SmartGames — Sudoku v1 PRD

**Version:** 1.0 | **Date:** 2026-03-10 | **Platform:** iOS 16+

---

## 1. Product Vision

A polished multi-game hub app for iOS. V1 ships Sudoku only. Revenue via Google AdMob (non-aggressive). Architecture designed from day 1 to add more games without structural rework. Primary metric: D7 retention > 20%.

---

## 2. Target Users

- Casual puzzle players, 25–55 years old
- Play in short sessions (5–15 min commute, lunch break)
- Expect clean, distraction-free UX — low tolerance for intrusive ads
- Mix of Sudoku beginners (Easy/Medium) and enthusiasts (Hard/Expert)

---

## 3. Screens

| Screen | Description |
|--------|-------------|
| **Game Hub** | Card list of all games. V1: Sudoku + "Coming Soon" placeholders. Gear → Settings. |
| **Settings** | Sound, haptics, highlight toggles. Privacy/Terms links. |
| **Sudoku Lobby** | Difficulty picker (Easy/Medium/Hard/Expert) + Daily Challenge card (Phase 2). Resume banner if in-progress game. |
| **Sudoku Game** | 9x9 board + toolbar (Undo/Eraser/Pencil/Hint) + number pad 1–9. Stats bar: mistakes, difficulty, timer. |
| **Pause Overlay** | Full-screen dim, board hidden. Resume / Restart / Quit buttons. |
| **Win Screen** | Completion stats (time, mistakes, star rating). Next Puzzle / Back to Menu. |
| **Lose Screen** | 3 mistakes reached. Try Again / New Game / Watch Ad to Continue. |

---

## 4. Gameplay Loop

```
Hub → Lobby → [difficulty selected] → Game
                                         ↓
                                    [Playing]
                                    ↙        ↘
                               [Paused]    [Mistake]
                                    ↘        ↙
                                    [Resume]
                                         ↓
                              [Win] ←→ [Lose (3 mistakes)]
                                ↓              ↓
                         [Win Screen]    [Lose Screen]
                                ↓              ↓
                           Next Puzzle    Try Again / New Game
                                ↓
                     [Optional Interstitial]
                                ↓
                              [Hub]
```

---

## 5. Core Features (V1 Scope)

### Must Have
- [x] 9x9 Sudoku board — standard rules
- [x] 4 difficulty levels: Easy, Medium, Hard, Expert
- [x] 500+ puzzles per difficulty (2000+ total)
- [x] Cell selection + row/col/box + same-number highlighting
- [x] Pencil mode (candidate marks)
- [x] Undo (up to 50 moves)
- [x] Eraser
- [x] Hint system (3 free per game, +3 via rewarded ad)
- [x] Mistake counter (0/3 limit)
- [x] Timer (count-up, MM:SS)
- [x] Star rating on win (1–3 stars)
- [x] Pause / Resume
- [x] Restart level
- [x] Auto-save game state
- [x] Resume in-progress game on relaunch
- [x] Rewarded ads (hints + continue after lose)
- [x] Light interstitial (max 1 per session, post-win)
- [x] Analytics events (Firebase)
- [x] ATT prompt
- [x] Settings (sound, haptics, highlights)

### Out of Scope (V1)
- Daily Challenge (Phase 2)
- Leaderboards / Game Center (Phase 2)
- User accounts / cloud sync (Phase 2)
- Multiple game themes / dark mode (Phase 2)
- Banner ads (never — too disruptive)
- Other mini-games (Phase 2+)
- IAP / remove ads (Phase 2)

---

## 6. Monetization Plan

### V1 Ad Strategy
| Ad Type | Placement | Frequency |
|---------|-----------|-----------|
| Rewarded | Hint refill (0 hints left) | On demand |
| Rewarded | Continue after lose | On demand |
| Interstitial | After win → before hub | Max 1/session |

**Philosophy:** Never interrupt gameplay. Ads only at natural break points (game end) or gated behind user choice (rewarded). Earn trust first.

### V1 Revenue Estimate (rough)
- DAU × ad eCPM assumptions to be validated post-launch via Firebase + AdMob dashboard
- Expected: $0.50–2.00 ARPU/month for engaged users (puzzle game benchmark)

### Phase 2 Monetization
- Remove Ads IAP ($2.99 one-time or $0.99/week)
- Hint packs IAP ($0.99 = 10 hints)
- Theme packs ($1.99)
- Subscription: SmartGames+ (all games + no ads) $2.99/month

---

## 7. Analytics Events Summary

Key events tracked (full list in phase-07):
- `sudoku_game_started` / `sudoku_game_completed` / `sudoku_game_abandoned`
- `sudoku_hint_exhausted` → monetization trigger
- `ad_rewarded_prompt_shown` / `ad_rewarded_completed`
- `att_permission_response`

Primary KPIs:
- D1/D7/D30 retention
- Games per session
- Hint exhaustion rate (monetization signal)
- Ad rewarded accept rate
- Difficulty distribution

---

## 8. Data Models Summary

```
SudokuPuzzle       — id, difficulty, givens[][], solution[][], board[][]
SudokuCell         — row, col, value, isGiven, pencilMarks, hasError
SudokuDifficulty   — easy/medium/hard/expert (enum)
SudokuGameState    — puzzle, elapsed, mistakes, hintsRemaining, undoStack
GameEntry          — id, displayName, iconAsset, isAvailable (hub model)
AnalyticsEvent     — name, parameters
```

---

## 9. Save / Progress Strategy

| Data | Storage | When Saved |
|------|---------|-----------|
| Active game state | UserDefaults (JSON) | Every move (debounced 500ms) + background |
| Per-difficulty stats | UserDefaults (JSON) | On game complete/fail |
| Hints balance | UserDefaults | On change |
| Played puzzle IDs | UserDefaults | On game start |
| Settings | UserDefaults | On change |

No CoreData / SwiftData in v1 — complexity not justified for this data volume.

---

## 10. Technical Architecture

**Stack:** Swift 5.9, SwiftUI, iOS 16+, MVVM, Google Mobile Ads SDK, Firebase Analytics + Crashlytics

**Pattern:** MVVM + EnvironmentObject services injected at app root

```
SmartGamesApp
├── AppEnvironment (EnvironmentObject)
│   ├── PersistenceService
│   ├── SettingsService
│   ├── SoundService + HapticsService
│   ├── AdsService (RewardedAdCoordinator, InterstitialAdCoordinator)
│   └── AnalyticsService
│
└── NavigationStack (AppRouter)
    ├── HubView ← HubViewModel
    ├── SudokuLobbyView ← SudokuLobbyViewModel
    └── SudokuGameView ← SudokuGameViewModel
                              └── SudokuEngine (Generator, Solver, Validator)
```

**Future game addition:** Create `Games/ParkingJam/` module, implement `GameModule` protocol, register in `HubViewModel.games`. Zero changes to shared services or hub layout.

---

## 11. Risk List

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Sudoku generator too slow on older devices | Medium | Pre-bundle 2000 puzzles; on-device gen is fallback only |
| AdMob review rejection | Medium | Follow AdMob policies strictly; ATT prompt correct timing |
| App Store review rejection (ads / privacy) | High | Privacy manifest, correct NSUserTrackingUsageDescription, ATT before first ad |
| Puzzle difficulty miscalibrated (Easy feels Hard) | Medium | Beta test with TestFlight users; tweak given count ranges |
| Interstitial ad too aggressive for v1 | Low | Already limited to 1/session; easy to disable via remote config later |
| FirebaseAnalytics / AdMob SDK bloat | Low | Both are standard in puzzle game category; file size < 50MB acceptable |
| iOS 16 vs 17 SwiftUI behavior differences | Low | Test on both; avoid iOS17-only APIs without fallback |
| Puzzle bank exhaustion (heavy players) | Low | 2000 puzzles + on-device generation = effectively unlimited |
| Retain cycle in GameViewModel timer | Medium | Use weak self in Task closures; Instruments allocation check |
| GoogleService-Info.plist committed to git | High | .gitignore + CI secret injection; enforce via pre-commit hook |

---

## 12. Implementation Roadmap

### Phase 1 — V1 (10 PRs, ~6–8 weeks)

| Week | PRs | Milestone |
|------|-----|-----------|
| 1 | PR-01, PR-02 | Project scaffold + shared services |
| 2 | PR-03, PR-04 | Hub screen + Sudoku engine |
| 3–4 | PR-05, PR-06 | Board UI + number input complete |
| 5 | PR-07 | Game state machine, timer, win/lose |
| 6 | PR-08, PR-09 | AdMob + Analytics live |
| 7–8 | PR-10 | Polish, testing, TestFlight, App Store submission |

---

### Phase 2 — Retention & Monetization (~4–6 weeks post-v1)

- **Daily Challenge** — server-seeded daily puzzle, streak counter, push notification
- **Game Center** — leaderboards (best time per difficulty)
- **Dark mode** + multiple board themes (Classic, Dark, Sepia)
- **IAP: Remove Ads** ($2.99 one-time)
- **IAP: Hint Packs** ($0.99 = 10 hints)
- **Difficulty progression UI** — visual level map or progress bar
- **Statistics screen** — games played, win %, average time, best time

---

### Phase 3 — Multi-Game Expansion (~8–12 weeks)

- **Second game: Merge Puzzle** or **Block Puzzle** (reference screenshots show these)
- **Third game: Parking Jam**
- **SmartGames+ subscription** — all games + no ads ($2.99/month)
- **Cross-game daily rewards** — play any game to maintain streak
- **Widget** — daily puzzle teaser on home screen
- **Remote Config** (Firebase) — tune ad frequency, difficulty params without App Store update

---

## 13. Assumptions

1. Target iOS 16+ (sufficient market coverage; avoids SwiftData requirement).
2. Portrait orientation only — locked in Info.plist.
3. App name "SmartGames" — availability check required before submission.
4. No user accounts in v1 — all data is local.
5. Puzzles use 3-mistake limit (as seen in reference screenshots).
6. Daily Challenge card visible in lobby (UI element) but shows "Coming Soon" state in v1 — or hidden entirely.
7. Mistake mode: wrong answers are shown in red temporarily; cell is still editable (not locked).
8. Timer direction: counts up from 00:00 (not countdown).
9. Star rating based on time + mistakes combined (formula defined in phase-05).
10. Interstitial shown after win → before returning to hub (user sees win screen first, ad only on dismiss).

---

## 14. Unresolved Questions

1. **App name:** Is "SmartGames" available on the App Store? Needs check before submission.
2. **Difficulty tuning:** Exact given counts for Hard/Expert may need beta calibration.
3. **Daily Challenge v1:** Show as "Coming Soon" card in lobby, or hide entirely until Phase 2?
4. **iOS minimum:** iOS 16 or 17? iOS 17 enables `@Observable` macro and SwiftData — simpler code but smaller addressable market. **Recommended: iOS 16** with `ObservableObject`.
5. **Ad network diversity:** AdMob only, or add ironSource/MAX mediation from day 1? Mediation improves fill rates but adds complexity. **Recommended: AdMob only in v1**, add mediation in Phase 2.
