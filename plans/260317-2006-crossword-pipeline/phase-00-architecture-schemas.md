---
phase: 0
title: "Architecture + Schemas"
status: completed
priority: P0
effort: 3h
completed: 2026-03-17
---

# Phase 0 — Architecture + Schemas

## Overview

Define all JSON schemas, config files, and directory structures before writing any pipeline code. This is the foundation everything else builds on.

## Deliverables

### 1. Pipeline Config (`pipeline/themes-config.json`)

```json
{
  "themes": {
    "animals": {
      "sources": ["imsky/animals", "imsky/dogs", "imsky/cats", "imsky/birds"],
      "minLength": 3,
      "maxLength": 10,
      "allowProperNouns": false,
      "targetDifficulty": { "easy": 0.4, "medium": 0.4, "hard": 0.2 }
    }
  },
  "global": {
    "minLength": 3,
    "maxLength": 12,
    "denylistPath": "data/denylist.txt",
    "allowlistPath": "data/allowlist.txt",
    "allowProperNouns": false,
    "allowPhrases": false,
    "normalizeToUppercase": true,
    "allowedCharsRegex": "^[A-Z]+$"
  },
  "boardSizes": {
    "mini": { "rows": 7, "cols": 7, "maxWordLength": 7 },
    "standard": { "rows": 9, "cols": 9, "maxWordLength": 9 },
    "extended": { "rows": 11, "cols": 11, "maxWordLength": 11 }
  }
}
```

### 2. Word Bank Entry Schema (`outputs/wordbanks/<theme>.json`)

```json
{
  "word": "DOLPHIN",
  "normalizedWord": "DOLPHIN",
  "theme": "ocean",
  "source": "imsky/animals",
  "sourceType": "topic_list",
  "difficulty": "medium",
  "popularityScore": 0.72,
  "crosswordFitScore": 0.85,
  "themeFitScore": 0.90,
  "allowInGame": true,
  "bannedReason": null,
  "tags": ["animal", "marine"],
  "clueCandidates": ["Intelligent marine mammal", "Flipper's species"],
  "notes": ""
}
```

### 3. Clue Entry Schema (`outputs/clues/<theme>.json`)

```json
{
  "word": "DOLPHIN",
  "primaryClue": "Intelligent marine mammal",
  "alternateClues": ["Flipper's species", "Playful sea creature"],
  "softHints": {
    "startsWith": "D",
    "length": 7,
    "category": "ocean"
  },
  "difficulty": "medium",
  "source": "template",
  "reviewFlags": [],
  "approved": true
}
```

### 4. Puzzle JSON Schema (`outputs/puzzles/<theme>/<difficulty>/<id>.json`)

```json
{
  "puzzleId": "ocean-medium-7x7-001",
  "seed": 42,
  "theme": "ocean",
  "difficulty": "medium",
  "rows": 7,
  "cols": 7,
  "solutionGrid": [["D","O","L","P","H","I","N"], ...],
  "playerGrid": [["","","","","","",""], ...],
  "entries": [
    {
      "number": 1,
      "answer": "DOLPHIN",
      "direction": "across",
      "row": 0,
      "col": 0,
      "length": 7,
      "clue": "Intelligent marine mammal",
      "softHints": { "startsWith": "D", "length": 7, "category": "ocean" },
      "theme": "ocean",
      "difficulty": "medium"
    }
  ],
  "clueGroups": {
    "across": [...],
    "down": [...]
  },
  "uiMetadata": {
    "rowGroups": [],
    "colGroups": []
  },
  "stats": {
    "placedWordCount": 8,
    "intersectionCount": 12,
    "fillRatio": 0.73,
    "generatorScore": 0.88
  }
}
```

### 5. Pack Schema (`outputs/packs/<packId>.json`)

```json
{
  "packId": "ocean-medium",
  "title": "Ocean Wonders",
  "theme": "ocean",
  "difficulty": "medium",
  "boardSize": "standard",
  "puzzleCount": 20,
  "createdAt": "2026-03-17",
  "version": "1.0.0",
  "puzzles": [ ... ]
}
```

### 6. Pack Index (`SmartGames/Games/Crossword/Resources/crossword-packs-index.json`)

```json
{
  "version": "1.0.0",
  "packs": [
    {
      "packId": "tutorial",
      "title": "Getting Started",
      "theme": "mixed",
      "difficulty": "easy",
      "boardSize": "mini",
      "puzzleCount": 5,
      "resourceFile": "crossword-pack-tutorial.json",
      "isUnlocked": true
    }
  ]
}
```

## Implementation Steps

1. Create `pipeline/` Python package structure with `__init__.py`
2. Write `pipeline/config.py` — loads and validates `themes-config.json`
3. Define all JSON schemas as Pydantic models or dataclasses in `pipeline/models.py`
4. Create `data/denylist.txt` with common profanity/unsafe terms
5. Create `data/allowlist.txt` (initially empty, for custom overrides)
6. Create `data/clue-overrides.json` (initially empty dict `{}`)
7. Write `LICENSE_NOTES.md` at repo root documenting each source
8. Create directory skeleton: `data/raw/`, `data/processed/`, `outputs/wordbanks/`, `outputs/clues/`, `outputs/puzzles/`, `outputs/packs/`

## Todo

- [ ] Create `pipeline/` package with `__init__.py`, `config.py`, `models.py`
- [ ] Write `themes-config.json` covering all 12 V1 themes
- [ ] Define Pydantic/dataclass models matching all 5 schemas above
- [ ] Create `data/denylist.txt`
- [ ] Create `LICENSE_NOTES.md`
- [ ] Create directory skeleton

## Success Criteria

- `python -c "from pipeline.config import load_config; print(load_config())"` succeeds
- All schemas importable and serializable
- Directory skeleton committed

## Related Files

- `pipeline/config.py` (new)
- `pipeline/models.py` (new)
- `data/denylist.txt` (new)
- `LICENSE_NOTES.md` (new)
