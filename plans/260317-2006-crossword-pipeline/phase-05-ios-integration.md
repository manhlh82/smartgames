---
phase: 5
title: "iOS Integration"
status: completed
priority: P1
effort: 6h
depends_on: [phase-04]
completed: 2026-03-17
---

# Phase 5 — iOS Integration

## Overview

Enhance existing iOS Crossword models and lobby to consume pack-based JSON. The game engine (ViewModel, grid, hints, persistence) is already complete — only the data layer and lobby need updating.

## Current State

- `CrosswordPuzzle` has: `id`, `difficulty` (mini/standard), `size`, `grid`, `clues`
- `CrosswordPuzzleBank` loads from one flat `crossword-puzzles.json`
- `CrosswordLobbyView` shows difficulty picker only

## Target State

- `CrosswordPuzzle` gains: `theme`, `packId`, `boardSize`, `softHints` per entry, `stats`
- New `CrosswordPack` model with metadata + embedded puzzles
- `CrosswordPuzzleBank` loads from `crossword-packs-index.json` + individual pack files
- `CrosswordLobbyView` shows theme tiles → difficulty → puzzle list

## Model Changes

### `CrosswordPuzzle.swift` — MODIFY

Add fields (all optional for backward compat with old hand-coded puzzles):
```swift
struct CrosswordPuzzle: Codable, Identifiable {
    let id: String
    let difficulty: CrosswordDifficulty
    let size: Int
    let grid: [[String]]
    let clues: [CrosswordClue]
    // NEW
    var theme: String?
    var packId: String?
    var boardSize: String?
    var stats: CrosswordPuzzleStats?
}

struct CrosswordPuzzleStats: Codable {
    let placedWordCount: Int
    let intersectionCount: Int
    let fillRatio: Double
    let generatorScore: Double
}
```

### `CrosswordClue.swift` — MODIFY (or extend `CrosswordClue`)

Add soft hints:
```swift
struct CrosswordClue: Codable, Identifiable {
    let number: Int
    let direction: ClueDirection
    let text: String
    let startRow: Int
    let startCol: Int
    let length: Int
    // NEW
    var softHints: CrosswordSoftHints?
    var theme: String?
}

struct CrosswordSoftHints: Codable {
    let startsWith: String
    let length: Int
    let category: String
}
```

### `CrosswordPack.swift` — NEW

```swift
struct CrosswordPackMeta: Codable, Identifiable {
    let packId: String
    let title: String
    let theme: String
    let difficulty: String
    let boardSize: String
    let puzzleCount: Int
    let resourceFile: String
    let isUnlocked: Bool
    let createdAt: String
    let version: String
    var id: String { packId }
}

struct CrosswordPack: Codable {
    let packId: String
    let title: String
    let theme: String
    let difficulty: String
    let boardSize: String
    let puzzles: [CrosswordPuzzle]
}

struct CrosswordPacksIndex: Codable {
    let version: String
    let packs: [CrosswordPackMeta]
}
```

### `CrosswordDifficulty` — MODIFY

Extend to support 3-tier pipeline difficulties while keeping legacy values:
```swift
enum CrosswordDifficulty: String, Codable, CaseIterable, Identifiable {
    case mini       // legacy 5×5
    case standard   // legacy 9×9
    case easy       // pipeline
    case medium     // pipeline
    case hard       // pipeline

    var gridSize: Int {
        switch self {
        case .mini: return 5
        case .standard, .easy, .medium: return 9
        case .hard: return 11
        }
    }
}
```

## Engine Changes

### `CrosswordPuzzleBank.swift` — MODIFY

```swift
final class CrosswordPuzzleBank {
    // NEW: load from pack index
    private func loadPackedPuzzles()
    func getPack(id: String) -> CrosswordPack?
    func allPackMeta() -> [CrosswordPackMeta]

    // KEEP: existing methods for backward compat
    func getPuzzle(for difficulty: CrosswordDifficulty) -> CrosswordPuzzle?
    func allPuzzles(for difficulty: CrosswordDifficulty) -> [CrosswordPuzzle]
}
```

Loading priority: try `crossword-packs-index.json` first; fall back to legacy `crossword-puzzles.json` if index not found.

## UI Changes

### `CrosswordLobbyView.swift` — MODIFY

New flow:
1. Show theme grid (2-column, emoji + name tiles for each available theme)
2. On theme tap → show difficulty row (Easy / Medium / Hard)
3. On difficulty select → show pack puzzle list (ScrollView of puzzle cards)
4. On puzzle tap → navigate to game

Keep existing difficulty-only flow as fallback when only legacy puzzles are loaded.

Theme display names + emoji:
```swift
let themeInfo: [String: (emoji: String, name: String)] = [
    "animals": ("🐾", "Animals"),
    "food":    ("🍕", "Food"),
    "ocean":   ("🌊", "Ocean"),
    "space":   ("🚀", "Space"),
    "nature":  ("🌿", "Nature"),
    "sports":  ("⚽", "Sports"),
    "music":   ("🎵", "Music"),
    "travel":  ("✈️", "Travel"),
    "city":    ("🏙️", "City"),
    "school":  ("📚", "School"),
    "weather": ("⛅", "Weather"),
    "fruits":  ("🍎", "Fruits"),
    "mixed":   ("🎯", "Mixed"),
]
```

## Hint UX Enhancement

Soft hints are now available from puzzle JSON. The hint toolbar can surface them:
- "Reveal first letter" → uses `softHints.startsWith`
- "Show word length" → uses `softHints.length` (already shown via clue)
- "Show category" → uses `softHints.category` (can display as badge)

No changes to `CrosswordGameViewModel` — it already handles hint actions. Just wire `softHints` data through where relevant.

## Persistence Key Changes

Add new keys to `PersistenceService.Keys`:
```swift
static let crosswordPackProgress = "crossword_pack_progress"  // [packId: Set<puzzleId>]
```

Track solved puzzles per pack so lobby can show completion badges.

## Implementation Steps

1. Add `CrosswordSoftHints`, `CrosswordPuzzleStats` structs to `CrosswordPuzzle.swift`
2. Add optional `softHints`, `theme` to `CrosswordClue`
3. Create `CrosswordPack.swift` with `CrosswordPackMeta`, `CrosswordPack`, `CrosswordPacksIndex`
4. Extend `CrosswordDifficulty` enum with easy/medium/hard cases
5. Update `CrosswordPuzzleBank` to load from pack index with legacy fallback
6. Update `CrosswordLobbyView` with theme grid + pack puzzle list
7. Add pack progress tracking key to `PersistenceService.Keys`
8. Add `crossword-packs-index.json` + pack files to Xcode project bundle

## Todo

- [ ] Extend `CrosswordPuzzle.swift` with new optional fields
- [ ] Create `CrosswordPack.swift`
- [ ] Update `CrosswordDifficulty` enum
- [ ] Update `CrosswordPuzzleBank.swift` — pack loading + legacy fallback
- [ ] Update `CrosswordLobbyView.swift` — theme grid UI
- [ ] Add `crosswordPackProgress` persistence key
- [ ] Add new resource files to `project.pbxproj`
- [ ] Verify existing gameplay unaffected (no regressions)

## Success Criteria

- App builds and runs with new pack-based loading
- Legacy `crossword-puzzles.json` still works if pack index absent
- Theme grid shows in lobby when packs are loaded
- Tapping a puzzle from pack navigates to game correctly
- Soft hints data available in active clue (even if not yet surfaced in UI)
- No regressions in gameplay, hints, save/load, daily challenge
