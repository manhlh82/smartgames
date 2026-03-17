# Research Report: Crossword Game — SmartGames iOS

**Date:** 2026-03-17
**Scope:** New Crossword game module following existing monetization/ads/diamond/hint patterns

---

## Executive Summary

Crossword is well-suited for SmartGames: strong word game audience, high replayability via daily puzzles, natural hint monetization (reveal letter / reveal word), and diamond-powered undo. The module follows the established `GameModule` protocol pattern and reuses all shared services (AdsService, DiamondService, GoldService, MonetizationConfig).

---

## 1. Data Model

### Puzzle Format (JSON)

Bundle 30–50 puzzles as `crossword-puzzles.json`. Each puzzle:

```json
{
  "id": "cw001",
  "rows": 11,
  "cols": 11,
  "grid": [
    ["#","#","A","P","P","L","E","#","#","#","#"],
    ...
  ],
  "clues": {
    "across": [
      { "number": 1, "row": 0, "col": 2, "length": 5, "clue": "A red fruit" },
      ...
    ],
    "down": [
      { "number": 1, "row": 0, "col": 2, "length": 4, "clue": "A tap or click" },
      ...
    ]
  }
}
```

- `"#"` = black/blocked cell
- Letters = solution characters (uppercased)
- Numbers assigned left-to-right, top-to-bottom (standard crossword numbering)

### Swift Model

```swift
// Models/CrosswordPuzzle.swift
struct CrosswordPuzzle: Codable, Identifiable {
    let id: String
    let rows: Int
    let cols: Int
    let grid: [[String]]   // "#" = black, else letter
    let clues: CrosswordClues
}

struct CrosswordClues: Codable {
    let across: [CrosswordClue]
    let down: [CrosswordClue]
}

struct CrosswordClue: Codable, Identifiable {
    let number: Int
    let row: Int           // start row
    let col: Int           // start col
    let length: Int
    let clue: String
    var id: String { "\(number)\(number < 100 ? "A" : "D")" }
}
```

### Board State

```swift
// Models/CrosswordBoardState.swift
struct CrosswordCell {
    let isBlack: Bool
    let solution: Character?
    var userInput: Character? = nil
    var isRevealed: Bool = false    // permanently revealed via hint
    var isChecked: Bool = false     // temporarily checked
    var clueNumber: Int? = nil      // printed number (1-based)
}
```

---

## 2. Grid Layout

### SwiftUI Grid

- Fixed-cell grid using `LazyVGrid` or manual `VStack/HStack`
- Cell size: `(screenWidth - padding) / cols` — typically 32–38pt for 11×11
- Black cells: `.black` fill; white cells: bordered square with letter
- Selected cell: accent highlight; active word cells: secondary highlight
- Clue number badge (top-left corner, small font) on numbered cells

### Input Model

- Tap cell → select that cell + its word direction (across or down)
- If cell belongs to both across and down, first tap selects across, second tap toggles to down
- Native iOS keyboard appears (`.keyboardType(.alphabet)`, `.autocorrectionDisabled()`)
- Each letter typed advances cursor to next empty cell in the word
- Backspace deletes current cell and moves cursor back
- Direction toggle button in toolbar

---

## 3. Hint Types & Monetization

### Hint Varieties (3 tiers)

| Tier | Action | Cost |
|------|--------|------|
| Check Letter | Highlights correct/wrong in selected cell | 1 hint |
| Reveal Letter | Fills selected cell permanently | 1 hint |
| Reveal Word | Fills all cells in active word | 3 hints |

### Hint Economy (follows Sudoku pattern)

```swift
// Reuse MonetizationConfig fields:
MonetizationConfig(
    bannerEnabled: true,
    interstitialEnabled: true,
    interstitialFrequency: 2,        // every 2 puzzles
    rewardedHintsEnabled: true,
    rewardedHintAmount: 3,           // ad gives 3 hints
    levelCompleteHintReward: 1,      // 1 hint on puzzle complete
    maxHintCap: 5,
    mistakeResetEnabled: false       // crossword has no mistakes concept
)
```

### Starting Hints
- Easy: 5 free hints; Medium: 3; Hard: 1

### Diamond Hint: Reveal Letter
- Cost: 1 diamond (same as undo)
- Use `DiamondService.spend(amount: DiamondReward.undoCost)` — no new constant needed
- Or add `DiamondReward.revealLetterCost = 1` alongside existing constants

### Ad Flow (same as Sudoku)
- `gamePhase == .needsHintAd` triggers hint ad alert
- On success: `grantHintsAfterAd()` → +3 hints (capped at maxHintCap)

---

## 4. Undo System

### Approach
- Undo stack (max depth 20 for crossword vs 50 for Sudoku — fewer moves matter)
- Each move pushes `CrosswordSnapshot` (copy of user inputs + cursor position)
- Free undo: unlimited within a session (no cost, like Sudoku's base undo)
- Diamond undo: if free undos exhausted (optional — alternatively always free)

### Recommendation
Keep undo **free** (no cost) for crossword — crossword players expect it. No rewarded ad needed for undo; maintain diamond undo only as optional premium. Simpler = better for word game audience.

---

## 5. Puzzle Sourcing

### Option A: Bundled JSON (Recommended for V1)
- Bundle 50+ hand-crafted or publicly licensed puzzles
- Sources: NYT Mini Crossword format (5×5), 11×11 standard themed puzzles
- Group by difficulty: Easy (9×9, simple vocab), Medium (11×11), Hard (13×13)
- Daily puzzle: deterministic selection by day number (seeded, same as Sudoku pattern)

### Option B: Programmatic Generation (V2)
- Use a word list (English dictionary) + backtracking grid fill
- Complex; NYT-quality requires human curation anyway
- Defer to V2

### Puzzle Count Target
- 30 Easy + 30 Medium + 20 Hard = 80 puzzles for launch
- 1 puzzle per day = 80 days of daily content before repeat

---

## 6. Game Module Structure

```
SmartGames/Games/Crossword/
├── CrosswordModule.swift           GameModule conformance
├── Engine/
│   ├── CrosswordPuzzleBank.swift   JSON loading + daily seeding
│   └── CrosswordValidator.swift   Check, reveal logic
├── Models/
│   ├── CrosswordPuzzle.swift       Data model
│   ├── CrosswordBoardState.swift   Cell + user input state
│   ├── CrosswordGameState.swift    Full game state (saveable)
│   └── CrosswordSnapshot.swift    Undo snapshot
├── ViewModels/
│   └── CrosswordGameViewModel.swift  State machine + hints/undo/ads
├── Views/
│   ├── CrosswordGameView.swift     Main screen + banner + overlays
│   ├── CrosswordGridView.swift     Grid rendering
│   ├── CrosswordCellView.swift     Individual cell
│   ├── CrosswordClueBarView.swift  Active clue display (above grid)
│   ├── CrosswordClueListView.swift Scrollable across/down clue list
│   ├── CrosswordToolbarView.swift  Hints, undo, direction toggle
│   ├── CrosswordLobbyView.swift    Difficulty select + daily
│   ├── CrosswordWinView.swift      Puzzle complete overlay
│   └── CrosswordPauseOverlay.swift Pause menu
└── Resources/
    └── crossword-puzzles.json
```

---

## 7. Game State Machine

```swift
enum CrosswordGamePhase: Equatable {
    case playing
    case paused
    case won
    case needsHintAd    // same pattern as Sudoku
}
```

---

## 8. AppEnvironment / AppRegistry Integration

Following existing pattern:
1. Register `CrosswordModule` in `AppEnvironment.init()` after Stack2048
2. No new daily challenge service needed for V1 — use shared `DailyChallengeService` or a simple `CrosswordDailyChallengeService` following `DropRushDailyChallengeService`
3. Add `crosswordDailyChallenge: CrosswordDailyChallengeService` to AppEnvironment
4. Inject in `SmartGamesApp` via `.environmentObject(environment.crosswordDailyChallenge)`

---

## 9. Analytics Events

```swift
// Extend AnalyticsEvent enum
case crosswordStarted(difficulty: String)
case crosswordCompleted(difficulty: String, hintsUsed: Int, timeSeconds: Int)
case crosswordAbandoned(difficulty: String)
case crosswordCheckUsed(difficulty: String)
case crosswordRevealLetterUsed(difficulty: String)
case crosswordRevealWordUsed(difficulty: String)
case crosswordUndoUsed(difficulty: String)
```

---

## 10. Key Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Puzzle source | Bundled JSON v1 | No server needed; fast launch |
| Grid size | 9×9 easy, 11×11 med, 13×13 hard | Standard; fits iPhone screen |
| Hint tiers | Check / Reveal Letter / Reveal Word | Familiar to NY Times / daily crossword users |
| Undo cost | Free (no diamond) | Word game convention; reduces friction |
| Diamond hint | Reveal Letter (1 ◆) | Matches existing economy |
| Daily puzzle | Seeded selection (same as Sudoku) | No server dependency |
| Input | Native iOS keyboard | No custom keyboard needed |

---

## 11. MonetizationConfig (Crossword-Specific)

```swift
MonetizationConfig(
    bannerEnabled: true,
    interstitialEnabled: true,
    interstitialFrequency: 2,
    rewardedHintsEnabled: true,
    rewardedHintAmount: 3,
    levelCompleteHintReward: 1,
    maxHintCap: 5,
    mistakeResetEnabled: false,
    mistakeResetUsesPerLevel: 0
)
```

---

## Unresolved Questions

1. **Puzzle content**: Who creates/curates the 80 bundled puzzles? Manual curation or existing CC-licensed dataset?
2. **Reveal Word cost**: 3 hints or 2? (3 is safe floor based on Sudoku's rewardedHintAmount matching reveal cost)
3. **Check Letter = free or 1 hint?** NYT mini is free check; our economy favors 1 hint cost.
4. **Keyboard handling**: iOS custom keyboard vs native `.textField` hidden approach — native is simpler but SwiftUI cell-tap + keyboard is non-trivial; need to test focus management.
5. **Pencil/draft mode**: Allow pencil letters in cells? (standard in hard crosswords) — add to V1 or defer?
6. **Daily challenge streak**: Reuse `DailyChallengeService` tracking or create `CrosswordDailyChallengeService`?
