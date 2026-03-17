---
phase: 3
title: "Crossword Generator"
status: completed
priority: P1
effort: 8h
depends_on: [phase-02]
completed: 2026-03-17
---

# Phase 3 — Crossword Generator

## Overview

Seed-based crossword board generator. Builds valid crossword grids from themed word banks using backtracking placement. Same seed always yields same board.

## Algorithm

### Word Selection
1. Load word bank for theme + difficulty
2. Sort by composite score: `0.4*popularity + 0.3*crosswordFit + 0.3*themeFit + 0.1*lengthFit`
3. Apply seeded shuffle to top-N candidates before placement attempts

### Placement Algorithm
```
1. Pick anchor word (longest + highest scored) → place horizontally at center
2. For each remaining candidate word:
   a. Find all valid intersection points with placed words
   b. Score each intersection (prefers crossing vowels, mid-word intersections)
   c. Try best intersection first; backtrack if constraint violated
3. Repeat from step 2 until no more words fit or word limit reached
4. Score the board
5. Restart with next seeded permutation if score < threshold
6. Keep best board across all restarts (default: 5 restarts)
```

### Constraint Validation (after each placement)
- No two words share the same cell unless they cross (one across, one down)
- No letter cell adjacent to another word's letter unless part of a valid crossing
- No word placed partially outside grid bounds
- Min word length 3 enforced
- No isolated letter islands

### Board Scoring
```
score = (
    0.30 * (placedWords / targetWords) +     # density
    0.25 * (intersections / placedWords) +   # connectivity
    0.20 * fillRatio +                       # grid utilization
    0.15 * avgWordQuality +                  # word quality
    0.10 * themeConsistency                  # % words from target theme
) - penalties
```

Penalties:
- `-0.05` per isolated word segment (no intersections)
- `-0.10` if fillRatio < 0.30

### Numbering
- Scan grid left-to-right, top-to-bottom
- Assign number to any cell that starts an across or down word
- Across: leftmost cell of a horizontal run of 2+
- Down: topmost cell of a vertical run of 2+
- Numbers are 1-indexed, sequential

## Board Sizes

| Size | Rows | Cols | Target words | Min words |
|------|------|------|-------------|-----------|
| mini | 7 | 7 | 6–8 | 4 |
| standard | 9 | 9 | 10–14 | 7 |
| extended | 11 | 11 | 14–20 | 10 |

## Implementation

### `pipeline/board.py`
```python
class Board:
    rows: int
    cols: int
    cells: list[list[str]]  # " " = empty, "#" = black, "A-Z" = letter

    def can_place(word, row, col, direction) -> bool
    def place(word, row, col, direction) -> list[PlacedEntry]
    def remove(entry: PlacedEntry)
    def get_intersections(word, direction) -> list[PlacementCandidate]
    def validate_constraints() -> bool
    def to_solution_grid() -> list[list[str]]
    def to_player_grid() -> list[list[str]]  # empty cells where letters go
    def score() -> float
    def assign_numbers() -> dict[tuple, int]
```

### `pipeline/generator.py`
```python
class CrosswordGenerator:
    def generate(
        theme: str,
        difficulty: str,
        board_size: str,
        seed: int,
        word_bank: list[WordEntry],
        clue_map: dict[str, ClueEntry],
        max_restarts: int = 5
    ) -> PuzzleOutput | None
```

### `scripts/generate-puzzle.py`
Single puzzle generation with preview output.

### `scripts/preview-puzzle.py`
ASCII grid preview for terminal inspection:
```
  1 2 3 4 5 6 7
1 D O L P H I N
2 # # A # # # #
3 W H A L E # #
4 # # # # # # #
...

ACROSS:
  1. Intelligent marine mammal (7)
  3. Largest ocean mammal (5)
DOWN:
  1. Ocean floor feature (5)
  2. Marine predator (5)
```

## Commands

```bash
# Generate single puzzle
python scripts/generate-puzzle.py --theme ocean --difficulty medium --size standard --seed 42

# Preview board in terminal
python scripts/preview-puzzle.py outputs/puzzles/ocean/medium/ocean-medium-9x9-042.json

# Batch generate for a theme
python scripts/generate-puzzle.py --theme ocean --difficulty medium --size standard --count 20
```

## Todo

- [ ] `pipeline/board.py` — Board class with placement + validation
- [ ] `pipeline/generator.py` — CrosswordGenerator with backtracking + restarts
- [ ] `scripts/generate-puzzle.py` — CLI entry point
- [ ] `scripts/preview-puzzle.py` — ASCII preview
- [ ] Unit tests for Board constraint validation
- [ ] Verify seed reproducibility (same seed → same board)
- [ ] Benchmark: standard 9×9 generation < 2s per puzzle

## Success Criteria

- `python scripts/generate-puzzle.py --theme ocean --difficulty medium --size standard --seed 42` produces valid puzzle
- Same seed always produces identical board (deterministic)
- Generated board has >= 7 words for standard size
- All entries have clues attached
- ASCII preview renders correctly
- Generation time < 5s per puzzle on standard laptop

## Risk

- Backtracking can be slow for 11×11 with small word banks — add timeout + fallback to smaller board
- Some theme/difficulty combos may have too few words — generator returns None, caller skips
