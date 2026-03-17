---
phase: 4
title: "Pack Export + Validation"
status: completed
priority: P1
effort: 4h
depends_on: [phase-03]
completed: 2026-03-17
---

# Phase 4 — Pack Export + Validation

## Overview

Assemble individual puzzles into named packs, validate integrity, and write final JSON files that the iOS app will bundle.

## Pack Types for V1

| Pack ID | Title | Theme | Difficulty | Size | Count |
|---------|-------|-------|------------|------|-------|
| tutorial | Getting Started | mixed | easy | mini (7×7) | 5 |
| animals-easy | Wild Kingdom | animals | easy | mini | 20 |
| animals-medium | Wild Kingdom Plus | animals | medium | standard | 20 |
| ocean-easy | Ocean Breeze | ocean | easy | mini | 20 |
| ocean-medium | Deep Blue | ocean | medium | standard | 20 |
| food-easy | Kitchen Fun | food | easy | mini | 20 |
| food-medium | Flavor World | food | medium | standard | 20 |
| space-medium | Space Explorer | space | medium | standard | 20 |
| nature-medium | Into the Wild | nature | medium | standard | 20 |
| mixed-hard | Challenge Pack | mixed | hard | extended (11×11) | 10 |

Total V1: 155 puzzles across 10 packs.

## Validation Rules (enforced before export)

- No duplicate `puzzleId` within a pack
- No puzzle with 0 entries
- All entries have non-empty `clue`
- All entries have `softHints.startsWith`, `softHints.length`, `softHints.category`
- `solutionGrid` and `playerGrid` have same dimensions = `rows × cols`
- Each entry's `answer` matches letters in `solutionGrid` at declared position
- Entry `direction` is "across" or "down"
- No answer appears twice in the same puzzle (unless explicitly allowed)
- Grid dimensions match declared `rows`/`cols`
- `stats.placedWordCount` matches `entries.length`

## Pack Index for iOS

`outputs/packs-index.json` → copied to `SmartGames/Games/Crossword/Resources/crossword-packs-index.json`

Each pack entry in index includes only metadata (no embedded puzzles):
```json
{
  "packId": "ocean-medium",
  "title": "Deep Blue",
  "theme": "ocean",
  "difficulty": "medium",
  "boardSize": "standard",
  "puzzleCount": 20,
  "resourceFile": "crossword-pack-ocean-medium.json",
  "isUnlocked": true,
  "createdAt": "2026-03-17",
  "version": "1.0.0"
}
```

## Implementation

### `pipeline/pack-builder.py`
```python
def build_pack(pack_config: PackConfig, puzzles: list[PuzzleOutput]) -> Pack
def validate_pack(pack: Pack) -> list[str]  # returns list of error messages
def write_pack(pack: Pack, output_dir: str)
def build_packs_index(packs: list[Pack]) -> PacksIndex
```

### `scripts/generate-pack.py`
```bash
# Generate single pack
python scripts/generate-pack.py --pack ocean-medium

# Generate all V1 packs
python scripts/generate-pack.py --all

# Validate existing packs without regenerating
python scripts/validate-outputs.py
```

### `scripts/validate-outputs.py`
- Load all pack JSON files
- Run all validation rules
- Print pass/fail per pack + per rule
- Exit code 1 if any validation fails (for CI use)

## iOS Resource Deployment

After pack generation, copy to iOS bundle:
```bash
# Copy pack index + all packs to iOS resources
cp outputs/packs-index.json SmartGames/Games/Crossword/Resources/crossword-packs-index.json
cp outputs/packs/*.json SmartGames/Games/Crossword/Resources/
```

This replaces the old `crossword-puzzles.json` (kept as fallback during transition).

## Todo

- [ ] `pipeline/pack-builder.py` — pack assembly + validation
- [ ] `scripts/generate-pack.py` — CLI entry point
- [ ] `scripts/validate-outputs.py` — standalone validator
- [ ] Define all 10 V1 packs in `pipeline/pack-definitions.json`
- [ ] Verify all packs pass validation
- [ ] Write copy script to deploy to iOS resources

## Success Criteria

- `python scripts/validate-outputs.py` exits 0 for all packs
- Each pack has correct puzzle count
- Pack index lists all packs with correct metadata
- Total puzzles: >= 155 across V1 packs
- All iOS resource files written correctly
