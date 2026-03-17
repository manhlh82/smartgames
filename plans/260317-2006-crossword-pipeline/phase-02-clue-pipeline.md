---
phase: 2
title: "Clue Pipeline"
status: completed
priority: P1
effort: 4h
depends_on: [phase-01]
completed: 2026-03-17
---

# Phase 2 — Clue Pipeline

## Overview

Generate at least one primary clue and soft hint metadata per word. No online AI required. Output is static JSON baked into puzzle packs.

## Clue Types

| Type | Description | Example |
|------|-------------|---------|
| `primaryClue` | Short natural-language clue | "Intelligent marine mammal" |
| `alternateClues` | Backup clues for variety | ["Flipper's species"] |
| `softHints.startsWith` | First letter reveal | "D" |
| `softHints.length` | Word length | 7 |
| `softHints.category` | Theme label | "ocean" |

## Generation Strategy (Priority Order)

1. **Source definitions** — if word bank entry has `clueCandidates` from BartMassey or WordNet, use cleanest one
2. **Template engine** — `pipeline/clue-templates.py` maps theme + word metadata → clue text
3. **Category fallback** — "A ___ animal" / "Something found in the ___" style
4. **AI-assisted** (behind `--ai` flag, not required) — calls local Ollama or Claude API

## Template Engine Design

Templates are keyed by `(theme, word_length_bucket, difficulty)`:

```python
TEMPLATES = {
    "ocean":   ["Found in the sea", "Marine ___", "Ocean creature: ___"],
    "animals": ["Type of animal", "___ that barks/roars/etc.", "Furry friend"],
    "food":    ["You eat this", "Found on a plate", "Kitchen staple"],
    "space":   ["Found in the cosmos", "Astronomical ___", "NASA studies this"],
    # ... per theme
}
```

For proper word-specific clues, use word metadata (length, first/last letter, vowel pattern) to select the most specific matching template.

## Clue Quality Rules

- Max 6 words in primary clue
- No direct letter giveaways as primary clue ("Starts with D")
- No obscure dictionary wording
- No unsafe/adult content (run through denylist)
- Soft hints are metadata only — not shown as primary clue
- `reviewFlags` populated if: clue is too short (< 3 words), clue contains the answer word, clue came from fallback-only

## Review Workflow

```bash
# Generate all clues
python scripts/build-clues.py

# Show clues needing review
python scripts/build-clues.py --show-flagged

# Apply manual overrides from data/clue-overrides.json
python scripts/build-clues.py --apply-overrides
```

`data/clue-overrides.json` structure:
```json
{
  "DOLPHIN": {
    "primaryClue": "Playful ocean mammal",
    "approved": true
  }
}
```

## Implementation Steps

1. `pipeline/clue-templates.py`
   - Define template dict for all 12 themes
   - `generate_clue(word_entry: WordEntry) -> ClueEntry`
   - Template selection: theme → word-specific if possible, else generic
   - Populate `reviewFlags` based on quality checks

2. `scripts/build-clues.py`
   - Read all `outputs/wordbanks/<theme>.json`
   - For each word: check `clueCandidates`, else template, else fallback
   - Write `outputs/clues/<theme>.json`
   - Print summary: total words, flagged count, source breakdown

## Commands

```bash
python scripts/build-clues.py
python scripts/build-clues.py --theme ocean
python scripts/build-clues.py --show-flagged
python scripts/build-clues.py --apply-overrides
```

## Output

```
outputs/clues/
├── animals.json
├── ocean.json
└── ...
```

## Todo

- [ ] `pipeline/clue-templates.py` — templates for all 12 themes
- [ ] `scripts/build-clues.py` — clue generation entry point
- [ ] Quality checks + `reviewFlags` population
- [ ] `data/clue-overrides.json` skeleton

## Success Criteria

- Every word in every word bank has a `primaryClue`
- < 10% of clues have `reviewFlags`
- No clue contains the answer word itself
- Soft hints (startsWith, length, category) populated for all entries
