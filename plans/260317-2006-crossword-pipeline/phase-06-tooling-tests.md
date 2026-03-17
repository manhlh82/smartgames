---
phase: 6
title: "Tooling + Tests + Docs"
status: completed
priority: P2
effort: 4h
depends_on: [phase-03, phase-04]
completed: 2026-03-17
---

# Phase 6 — Tooling, Tests, and Dev Experience

## Overview

End-to-end pipeline command, unit tests for critical pipeline components, sample artifacts, and developer documentation.

## CLI Commands Summary

```bash
# 1. Fetch/sync all source word lists
python scripts/fetch-wordlists.py

# 2. Build all themed word banks
python scripts/build-wordbank.py [--theme <name>] [--dry-run]

# 3. Build clues for all words
python scripts/build-clues.py [--theme <name>] [--show-flagged] [--apply-overrides]

# 4. Generate a single puzzle (dev/preview)
python scripts/generate-puzzle.py --theme ocean --difficulty medium --size standard --seed 42

# 5. Preview puzzle in terminal
python scripts/preview-puzzle.py outputs/puzzles/ocean/medium/ocean-medium-9x9-042.json

# 6. Generate all V1 packs
python scripts/generate-pack.py --all

# 7. Validate all outputs
python scripts/validate-outputs.py

# 8. Full end-to-end pipeline (all steps)
bash scripts/run-pipeline.sh
```

## `scripts/run-pipeline.sh`

```bash
#!/usr/bin/env bash
set -e
echo "=== Crossword Content Pipeline ==="
python scripts/fetch-wordlists.py
python scripts/build-wordbank.py
python scripts/build-clues.py
python scripts/generate-pack.py --all
python scripts/validate-outputs.py
echo "=== Copying to iOS resources ==="
cp outputs/packs-index.json SmartGames/Games/Crossword/Resources/crossword-packs-index.json
cp outputs/packs/*.json SmartGames/Games/Crossword/Resources/
echo "=== Done ==="
```

## Tests

### Python Unit Tests (`tests/`)

```
tests/
├── test_normalization.py      ← normalize_word edge cases
├── test_scoring.py            ← all scoring functions
├── test_clue_generation.py    ← clue quality guards
├── test_board.py              ← Board placement + constraint validation
├── test_generator.py          ← deterministic generation with seed
├── test_pack_validation.py    ← pack integrity rules
└── test_schema.py             ← JSON schema round-trip
```

Key test cases:
- `normalize_word("café")` → `None` (non-ASCII)
- `normalize_word("don't")` → `None` (apostrophe)
- `normalize_word("WHALE")` → `"WHALE"`
- `compute_crossword_fit("AEIOU")` < `compute_crossword_fit("WHALE")` (poor vowel balance)
- `CrosswordGenerator.generate(seed=42)` called twice → identical output
- Board with placed word "CAT" across row 0 col 0: `can_place("DOG", 0, 0, "across")` → False
- Pack with duplicate puzzleId → validation fails
- Entry answer mismatch with solutionGrid → validation fails

Run:
```bash
python -m pytest tests/ -v
```

### iOS Decode Tests

Add `CrosswordPackDecodingTests.swift` to test target:
- Load each bundled pack JSON and decode — no decode errors
- Verify pack puzzle count matches `puzzleCount` in index
- Verify all entries decode with required fields
- Verify `CrosswordPuzzle` decodes both legacy format and new pipeline format

## Sample Artifacts

Commit sample generated files for dev reference and CI validation:
```
outputs/samples/
├── wordbank-ocean-sample.json      (20 words)
├── clues-ocean-sample.json         (20 entries)
├── puzzle-ocean-medium-9x9-sample.json
└── pack-ocean-medium-sample.json   (3 puzzles)
```

## Documentation

### `scripts/README.md`
- Prerequisites (Python 3.11+, pip install -r requirements.txt)
- Quick start (run `bash scripts/run-pipeline.sh`)
- Per-script usage + flags
- Output directory structure
- How to add a new theme
- How to override a bad clue

### `LICENSE_NOTES.md` (repo root)
```markdown
# License Notes

## Build-Time Sources (not shipped in app)

| Source | License | URL | Usage |
|--------|---------|-----|-------|
| imsky/wordlists | MIT | github.com/imsky/wordlists | Topic word lists for theme assignment |
| BartMassey/wordlists | MIT | github.com/BartMassey/wordlists | Frequency ranking for popularity scoring |
| christophsjones/crossword-wordlist | MIT | github.com/christophsjones/crossword-wordlist | Crossword fit scoring enrichment |

## Shipped in App

Only normalized word banks (A-Z uppercase words) and generated puzzle JSON are shipped.
Raw source files are never included in the app bundle.
All shipped content is derived from MIT-licensed sources and is safe for commercial use.
```

### `TROUBLESHOOTING.md`
- "Word bank is empty for theme X" → check themes-config.json source paths
- "Generator returns None" → word bank too small; add words to allowlist
- "Validation fails: answer mismatch" → re-run generator, likely bug in board.py
- "iOS app shows legacy puzzles only" → check crossword-packs-index.json is in bundle

## requirements.txt

```
pytest>=7.0
pydantic>=2.0
```

No heavy dependencies — pipeline is pure Python stdlib + pydantic for schema validation.

## Todo

- [ ] `scripts/run-pipeline.sh` end-to-end script
- [ ] `tests/test_normalization.py`
- [ ] `tests/test_scoring.py`
- [ ] `tests/test_board.py`
- [ ] `tests/test_generator.py` (seed determinism)
- [ ] `tests/test_pack_validation.py`
- [ ] `CrosswordPackDecodingTests.swift` in iOS test target
- [ ] `scripts/README.md`
- [ ] `LICENSE_NOTES.md`
- [ ] `TROUBLESHOOTING.md`
- [ ] `requirements.txt`
- [ ] Commit sample artifacts to `outputs/samples/`

## Success Criteria

- `bash scripts/run-pipeline.sh` completes end-to-end without errors
- `python -m pytest tests/ -v` — all tests pass
- iOS decode tests pass for all bundled packs
- README covers quick-start in < 5 steps
- LICENSE_NOTES.md documents all 3 sources
