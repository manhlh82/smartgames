# Phase 01 — Models + Engine

## Context Links
- [plan.md](plan.md) — overview
- Pattern ref: `SmartGames/Games/Sudoku/Models/SudokuPuzzle.swift`, `SudokuCell.swift`
- Pattern ref: `SmartGames/Games/Sudoku/Engine/PuzzleBank.swift`, `SudokuValidator.swift`

## Overview
- **Priority:** P1 (foundation for all other phases)
- **Status:** pending
- Define crossword data models, JSON puzzle format, puzzle bank loader, and win validator.

## Key Insights
- Crossword grid uses `"#"` for black cells, letter chars for solution
- Clues are embedded per-puzzle in JSON (across + down arrays)
- Each cell needs: row, col, solution char, clue number (optional), user input char
- Board state tracks per-cell user input + reveal status (for hint system)
- Puzzles are static JSON — no generator needed (unlike Sudoku)

## Requirements
- `CrosswordPuzzle`: parsed puzzle with grid, clues, metadata
- `CrosswordBoardState`: mutable play state (user entries, revealed flags)
- `CrosswordGameState`: saveable snapshot (puzzle + board + timer + hints + undo)
- `CrosswordPuzzleBank`: load from JSON, track played IDs, return unplayed puzzle
- `CrosswordValidator`: check if board is fully and correctly filled
- `crossword-puzzles.json`: ~20 puzzles (mix of 5x5 mini + 9x9 standard)

## Architecture

### CrosswordPuzzle.swift
```
struct CrosswordClue: Codable, Identifiable
  - id: String (e.g. "1A", "3D")
  - number: Int
  - direction: ClueDirection (.across / .down)
  - text: String
  - startRow: Int, startCol: Int
  - length: Int

enum ClueDirection: String, Codable { case across, down }

enum CrosswordDifficulty: String, Codable, CaseIterable
  - mini, standard

struct CrosswordPuzzle: Codable, Identifiable
  - id: String
  - difficulty: CrosswordDifficulty
  - size: Int (5 or 9)
  - grid: [[String]] — "#" = black, letter = solution
  - clues: [CrosswordClue]
  - freeHints: Int (5 for mini, 3 for standard)
```

### CrosswordBoardState.swift
```
struct CrosswordCellState: Codable
  - userEntry: Character?
  - isRevealed: Bool (permanently filled by hint)
  - isBlack: Bool
  - clueNumber: Int? (displayed top-left)

struct CrosswordBoardState: Codable
  - cells: [[CrosswordCellState]]
  - init(from puzzle: CrosswordPuzzle)

struct CrosswordBoardSnapshot: Codable
  - cells: [[CrosswordCellState]]
```

### CrosswordGameState.swift
```
struct CrosswordGameState: Codable
  - puzzle: CrosswordPuzzle
  - boardState: CrosswordBoardState
  - elapsedSeconds: Int
  - hintsRemaining: Int
  - hintsUsedTotal: Int
  - undoStack: [CrosswordBoardSnapshot]
```

### CrosswordValidator.swift
Pure logic, no SwiftUI imports.
```
struct CrosswordValidator
  - func isSolved(board: CrosswordBoardState, puzzle: CrosswordPuzzle) -> Bool
  - func isLetterCorrect(row: Int, col: Int, board: CrosswordBoardState, puzzle: CrosswordPuzzle) -> Bool
  - func wordCells(for clue: CrosswordClue) -> [(row: Int, col: Int)]
```

### CrosswordPuzzleBank.swift
Follow `PuzzleBank.swift` pattern.
```
final class CrosswordPuzzleBank
  - init(persistence: PersistenceService)
  - func getPuzzle(for difficulty: CrosswordDifficulty) -> CrosswordPuzzle?
  - private loadBundledPuzzles()
  - private loadPlayedIDs() -> Set<String>
  - private markAsPlayed(puzzleID: String)
```

### crossword-puzzles.json
```json
{
  "mini": [
    {
      "id": "mini-001",
      "size": 5,
      "grid": [["C","A","T","#","#"], ...],
      "clues": [
        {"number": 1, "direction": "across", "text": "Feline pet", "startRow": 0, "startCol": 0, "length": 3},
        ...
      ]
    }
  ],
  "standard": [...]
}
```

Create at least 10 mini + 10 standard puzzles. Keep clues simple, age-appropriate.

## Related Code Files
- **Create:** `SmartGames/Games/Crossword/Models/CrosswordPuzzle.swift`
- **Create:** `SmartGames/Games/Crossword/Models/CrosswordBoardState.swift`
- **Create:** `SmartGames/Games/Crossword/Models/CrosswordGameState.swift`
- **Create:** `SmartGames/Games/Crossword/Engine/CrosswordValidator.swift`
- **Create:** `SmartGames/Games/Crossword/Engine/CrosswordPuzzleBank.swift`
- **Create:** `SmartGames/Games/Crossword/Resources/crossword-puzzles.json`

## Implementation Steps
1. Create directory structure: `SmartGames/Games/Crossword/{Models,Engine,ViewModels,Views,Services,Resources}/`
2. Implement `CrosswordPuzzle.swift` — all model structs + enums
3. Implement `CrosswordBoardState.swift` — cell state + board init from puzzle
4. Implement `CrosswordGameState.swift` — saveable game snapshot
5. Implement `CrosswordValidator.swift` — isSolved, isLetterCorrect, wordCells
6. Implement `CrosswordPuzzleBank.swift` — JSON loading, played tracking
7. Create `crossword-puzzles.json` with ~20 hand-coded puzzles
8. Add persistence keys to `PersistenceService.Keys`: `crossword.playedPuzzleIDs`, `crossword.activeGame`, `crossword.hints.remaining`
9. Run `xcodegen generate` and compile check

## Todo List
- [ ] Create Crossword directory structure
- [ ] CrosswordPuzzle model + enums
- [ ] CrosswordBoardState model
- [ ] CrosswordGameState model
- [ ] CrosswordValidator (pure logic)
- [ ] CrosswordPuzzleBank (JSON loader)
- [ ] crossword-puzzles.json (~20 puzzles)
- [ ] Add PersistenceService.Keys
- [ ] Compile check passes

## Success Criteria
- All models are Codable and round-trip through JSON
- Validator correctly identifies solved/unsolved boards
- PuzzleBank loads all puzzles from JSON without crash
- No SwiftUI imports in Engine files
- Compile succeeds after xcodegen
