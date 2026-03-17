# Crossword Content Pipeline

Automated pipeline to generate crossword puzzle packs for the SmartGames iOS app.

## Prerequisites

- Python 3.11+
- `pip install pytest` (for running tests)

## Quick Start

```bash
# Run full pipeline (fetch → build → generate → validate → copy to iOS)
bash scripts/run-pipeline.sh
```

## Individual Steps

| Step | Command | Description |
|------|---------|-------------|
| 1 | `python3 scripts/fetch-wordlists.py` | Download source word lists |
| 2 | `python3 scripts/build-wordbank.py` | Build themed word banks |
| 3 | `python3 scripts/build-clues.py` | Generate clues for all words |
| 4 | `python3 scripts/generate-pack.py --all` | Generate all puzzle packs |
| 5 | `python3 scripts/validate-outputs.py` | Validate pack integrity |

### Options

```bash
# Build only one theme
python3 scripts/build-wordbank.py --theme ocean

# Generate one pack
python3 scripts/generate-pack.py --pack ocean-medium

# Preview a puzzle in terminal
python3 scripts/preview-puzzle.py outputs/puzzles/ocean/medium/ocean-medium-9x9-0042.json
```

## Output Structure

```
outputs/
├── wordbanks/   # Per-theme word lists
├── clues/       # Generated clues per theme
├── puzzles/     # Individual puzzle JSON files
└── packs/       # Final puzzle packs for iOS
```

## Running Tests

```bash
python3 -m pytest tests/ -v
```

## Adding a New Theme

1. Add theme entry to `pipeline/themes-config.json`
2. Add templates to `pipeline/clue_templates.py`
3. Re-run the pipeline

## Overriding a Clue

Edit `data/clue-overrides.json`:
```json
{ "WHALE": { "primaryClue": "Largest ocean mammal", "approved": true } }
```

Then run: `python3 scripts/build-clues.py --apply-overrides`
