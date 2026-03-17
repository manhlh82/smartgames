---
phase: 1
title: "Word Bank Builder"
status: completed
priority: P1
effort: 6h
depends_on: [phase-00]
completed: 2026-03-17
---

# Phase 1 — Word Bank Builder

## Overview

Python pipeline that fetches open-source word lists, normalizes entries, scores them, and exports themed word banks to JSON. One command rebuilds everything from scratch.

## Sources

| Source | License | Use | Notes |
|--------|---------|-----|-------|
| imsky/wordlists | MIT | Topic word lists per theme | Best for theme coverage |
| BartMassey/wordlists | MIT | Frequency + general dict | Best for popularity scoring |
| christophsjones/crossword-wordlist | MIT | Crossword-optimized scores | Optional enrichment |
| Local allowlist/denylist | Own | Custom control | Always applied |

All sources are MIT — safe to use at build time. Only normalized word banks (no raw source files) are shipped in the app.

## Normalization Rules

- Uppercase all output
- A-Z only (strip accents, reject numerals, hyphens, apostrophes)
- Min length: 3 (configurable), max: 12 (configurable per board size)
- Deduplicate case-insensitively
- Reject multiword phrases (contain space after normalization)
- Apply denylist (case-insensitive exact match)
- Apply allowlist to whitelist borderline words

## Scoring

### popularityScore (0.0–1.0)
- Derived from BartMassey frequency rank when available
- Fallback: 0.5 if not in frequency list
- Common short words (3–5 letters from top-10k) get 0.8+

### crosswordFitScore (0.0–1.0)
- Letter diversity: unique letter count / word length (higher = better crossword intersections)
- Vowel ratio: penalize if < 0.2 or > 0.7
- Length fitness: words 4–8 letters score highest
- Formula: `0.4 * diversity + 0.3 * vowelBalance + 0.3 * lengthFit`

### themeFitScore (0.0–1.0)
- 1.0 if word came from a topic list matching this theme
- 0.5 if from general dictionary
- 0.3 if from frequency list only

### difficulty assignment
- easy: popularityScore >= 0.65 AND crosswordFitScore >= 0.6
- hard: popularityScore < 0.40 OR crosswordFitScore < 0.45
- medium: everything else

## Implementation Steps

1. `scripts/fetch-wordlists.py`
   - Clone/download imsky/wordlists to `data/raw/imsky/`
   - Download BartMassey word frequency files to `data/raw/bartmassey/`
   - Download christophsjones list to `data/raw/crossword-scored/`
   - Make idempotent: skip if already downloaded

2. `pipeline/normalization.py`
   - `normalize_word(word: str) -> str | None` — returns None if rejected
   - `is_valid_word(word: str, config: Config) -> tuple[bool, str | None]` — (valid, bannedReason)

3. `pipeline/scoring.py`
   - `compute_popularity(word, freq_map) -> float`
   - `compute_crossword_fit(word) -> float`
   - `compute_theme_fit(word, source_type) -> float`
   - `assign_difficulty(popularity, crossword_fit) -> str`

4. `scripts/build-wordbank.py`
   - Load config from `themes-config.json`
   - For each theme: load all mapped source files, normalize, score, deduplicate
   - Write `outputs/wordbanks/<theme>.json`
   - Write `outputs/wordbanks/all.json` (merged, deduplicated)
   - Print summary stats per theme

## Commands

```bash
# Download/sync all source data
python scripts/fetch-wordlists.py

# Build all themed word banks
python scripts/build-wordbank.py

# Build a single theme
python scripts/build-wordbank.py --theme ocean

# Dry run (show stats, don't write)
python scripts/build-wordbank.py --dry-run
```

## Expected Output

```
outputs/wordbanks/
├── animals.json    (~400 words)
├── food.json       (~350 words)
├── ocean.json      (~200 words)
├── space.json      (~180 words)
└── all.json        (~2800 words total)
```

Each file: array of word entry objects matching Phase 0 schema.

## Todo

- [ ] `pipeline/normalization.py` — normalize + validate
- [ ] `pipeline/scoring.py` — all scoring functions
- [ ] `scripts/fetch-wordlists.py` — source download
- [ ] `scripts/build-wordbank.py` — main pipeline entry
- [ ] `data/denylist.txt` — ~200 unsafe/profanity terms
- [ ] Verify output for each of 12 themes has >= 50 easy + 50 medium words

## Success Criteria

- `python scripts/build-wordbank.py` completes without errors
- Each theme bank has >= 100 allowInGame words
- Easy/medium/hard split is roughly 40/40/20
- No profanity in output (spot-check)
- Output valid JSON matching schema

## Risk

- Some themes (space, school) may have sparse word lists from imsky → augment with curated local additions in `data/allowlist.txt`
- BartMassey frequency list may use different casing/format — add parsing fallback
