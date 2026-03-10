# Phase 04 — Sudoku Engine

**Priority:** Critical | **Effort:** L | **PR:** PR-04

---

## Overview

Pure logic layer — no UI. Puzzle generation, solving, validation, and difficulty classification. This is the heart of the game. UI depends on this but this module has zero SwiftUI imports.

---

## PR-04 Goal

Implement `SudokuGenerator`, `SudokuSolver`, `SudokuValidator`, core data models, and bundled puzzle bank JSON (~1000+ puzzles per difficulty). All covered by unit tests.

---

## Data Models

```swift
// SudokuDifficulty.swift
enum SudokuDifficulty: String, Codable, CaseIterable {
    case easy, medium, hard, expert

    var displayName: String { rawValue.capitalized }

    // Approximate number of givens (clues) per difficulty
    var givenRange: ClosedRange<Int> {
        switch self {
        case .easy:   return 36...46
        case .medium: return 27...35
        case .hard:   return 22...26
        case .expert: return 17...21
        }
    }

    // Max mistakes allowed (from UI reference: 3)
    var mistakeLimit: Int { 3 }
}

// SudokuCell.swift
struct SudokuCell: Codable, Equatable {
    let row: Int                        // 0-8
    let col: Int                        // 0-8
    var value: Int?                     // nil = empty, 1-9 = filled
    let isGiven: Bool                   // pre-filled clue, immutable
    var pencilMarks: Set<Int>           // candidate notes (pencil mode)
    var isHighlighted: Bool             // same-number highlight (UI only, not persisted)
    var hasError: Bool                  // conflict detected (UI only)
}

// SudokuPuzzle.swift
struct SudokuPuzzle: Codable, Identifiable {
    let id: String                      // UUID string
    let difficulty: SudokuDifficulty
    let givens: [[Int?]]               // 9x9, nil = empty
    let solution: [[Int]]              // 9x9 complete solution
    var board: [[SudokuCell]]          // current state (mutable during play)
}
```

---

## SudokuGenerator

**Algorithm: Backtracking + Constraint Propagation**

```swift
final class SudokuGenerator {
    /// Generate a valid puzzle for given difficulty.
    /// Uses backtracking to fill a complete solution, then removes
    /// cells while ensuring unique solution (via solver check).
    func generate(difficulty: SudokuDifficulty) -> SudokuPuzzle

    // Internal
    private func fillBoard() -> [[Int]]       // random valid complete board
    private func removeClues(_ board: [[Int]], difficulty: SudokuDifficulty) -> [[Int?]]
    private func hasUniqueSolution(_ givens: [[Int?]]) -> Bool
}
```

**Steps:**
1. Start with empty 9x9 grid
2. Fill using backtracking with random number ordering (ensures different puzzles)
3. Remove cells one by one; after each removal, verify unique solution using solver
4. Stop when target given count reached for difficulty

**Performance:** Generation takes 10-500ms depending on difficulty. Done off main thread via `Task { await ... }`.

---

## SudokuSolver

```swift
final class SudokuSolver {
    /// Returns number of solutions (stop at 2 — 0=invalid, 1=unique, 2+=not unique)
    func countSolutions(_ board: [[Int?]], limit: Int = 2) -> Int

    /// Returns first valid solution or nil
    func solve(_ board: [[Int?]]) -> [[Int]]?

    // Internal — constraint propagation + backtracking
    private func propagate(_ board: inout [[Int?]]) -> Bool
    private func backtrack(_ board: inout [[Int?]], solutions: inout Int, limit: Int)
}
```

---

## SudokuValidator

```swift
final class SudokuValidator {
    /// Check if placing `value` at (row, col) conflicts with current board
    func isValid(value: Int, row: Int, col: Int, board: [[Int?]]) -> Bool

    /// Check if board is fully and correctly filled
    func isSolved(_ board: [[SudokuCell]]) -> Bool

    /// Find all cells that conflict with each other
    func findConflicts(_ board: [[SudokuCell]]) -> Set<CellPosition>

    /// Return valid candidates for a cell (for hint system)
    func candidates(row: Int, col: Int, board: [[Int?]]) -> Set<Int>
}

struct CellPosition: Hashable {
    let row: Int, col: Int
}
```

---

## Puzzle Bank Strategy

**Hybrid approach:**
- **Bundled puzzles** (primary): `Resources/Sudoku/puzzles.json` — 1000+ pre-generated puzzles per difficulty (4000 total). Generated via a Swift script run at build time.
- **On-device generation** (fallback): When bundled puzzles exhausted, generate on-device async.

**Puzzle bank JSON format:**
```json
{
  "easy": [
    {
      "id": "uuid",
      "givens": [[6,0,0,8,0,0,0,4,1], ...],
      "solution": [[6,3,2,8,5,7,9,4,1], ...]
    }
  ],
  "medium": [...],
  "hard": [...],
  "expert": [...]
}
```

**Puzzle selection:**
- Track played puzzle IDs in PersistenceService
- Select random unplayed puzzle for difficulty
- Once all played, shuffle and replay (or generate new)

---

## Hint System Logic

```swift
// In SudokuValidator
func getHint(for board: [[SudokuCell]], solution: [[Int]]) -> CellPosition? {
    // Return position of first empty cell where only one candidate exists,
    // or random empty cell if all have multiple candidates
}
```

Hint reveals the correct value for one cell. Decrements hint counter.

**Hint budget:**
- Free hints per game: 3 (configurable)
- Watch rewarded ad → +3 hints

---

## Pencil Mode

Pencil marks are stored on `SudokuCell.pencilMarks: Set<Int>`. When user switches to pencil mode and taps a number:
- Toggles that number in the cell's pencil marks (add if absent, remove if present)
- Does NOT set `cell.value`
- Pencil marks auto-cleared when the cell gets a confirmed value

---

## Files to Create

| File | Purpose |
|------|---------|
| `Games/Sudoku/Engine/SudokuGenerator.swift` | Puzzle generation |
| `Games/Sudoku/Engine/SudokuSolver.swift` | Solver + uniqueness check |
| `Games/Sudoku/Engine/SudokuValidator.swift` | Move validation + hints |
| `Games/Sudoku/Models/SudokuPuzzle.swift` | Puzzle data model |
| `Games/Sudoku/Models/SudokuCell.swift` | Cell model |
| `Games/Sudoku/Models/SudokuDifficulty.swift` | Difficulty enum |
| `Resources/Sudoku/puzzles.json` | Pre-generated puzzle bank |
| `scripts/GeneratePuzzles.swift` | Build-time puzzle generator script |

---

## Acceptance Criteria

- [ ] `SudokuGenerator.generate(difficulty:)` produces valid puzzles for all 4 difficulties
- [ ] `SudokuSolver` confirms all generated puzzles have exactly 1 solution
- [ ] `SudokuValidator.isValid` correctly rejects all invalid placements
- [ ] `SudokuValidator.isSolved` returns true only for complete correct boards
- [ ] `puzzles.json` contains ≥ 500 puzzles per difficulty
- [ ] Generation completes < 1 second per puzzle on iPhone 12+

---

## Tests Needed

- `SudokuGeneratorTests` — generated puzzles are valid, unique solution, correct given count per difficulty
- `SudokuSolverTests` — solve known puzzles, detect invalid boards
- `SudokuValidatorTests` — isValid/isSolved/findConflicts/candidates edge cases
- Performance test — 100 puzzle generations < 30s

---

## Dependencies

- PR-01 (folder structure)
- No UI dependencies — pure Swift, testable in isolation
