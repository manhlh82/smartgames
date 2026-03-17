---
title: "Crossword Content Pipeline"
description: "End-to-end pipeline: word banks → clue generation → crossword generator → puzzle packs → iOS integration"
status: completed
priority: P1
effort: 32h
branch: main
tags: [crossword, pipeline, word-bank, generator, content]
created: 2026-03-17
completed: 2026-03-17
---

# Crossword Content Pipeline

## Context

The iOS Crossword game module is already complete (MVVM, hints, daily challenges, save/load, monetization). The current puzzle bank is ~28KB of hand-coded JSON with 5×5 and 9×9 puzzles.

This plan replaces hand-coded puzzles with a fully automated offline content pipeline that produces themed puzzle packs consumed by the existing iOS app.

## Architecture

```
data/raw/          ← fetched source word lists
data/processed/    ← normalized + scored word banks
outputs/wordbanks/ ← per-theme JSON word banks
outputs/clues/     ← clue records per word
outputs/puzzles/   ← individual puzzle JSON files
outputs/packs/     ← pack bundles for iOS app
scripts/           ← Python pipeline scripts
pipeline/          ← Python library code
```

iOS app reads from `SmartGames/Games/Crossword/Resources/` which receives:
- `crossword-packs-index.json` — list of all packs
- `crossword-pack-<id>.json` — individual pack with embedded puzzles

## Phases

| # | Phase | Key Deliverable | Status |
|---|-------|----------------|--------|
| 0 | [Architecture + Schemas](phase-00-architecture-schemas.md) | Design doc, JSON schemas, config files | ✅ completed |
| 1 | [Word Bank Builder](phase-01-word-bank-builder.md) | Python pipeline, themed word banks (916 words, 12 themes) | ✅ completed |
| 2 | [Clue Pipeline](phase-02-clue-pipeline.md) | Clue generation + review workflow (all words) | ✅ completed |
| 3 | [Crossword Generator](phase-03-crossword-generator.md) | Seed-based board generator | ✅ completed |
| 4 | [Pack Export](phase-04-pack-export.md) | Pack bundles + validation (185 puzzles, 10 packs) | ✅ completed |
| 5 | [iOS Integration](phase-05-ios-integration.md) | Enhanced models, theme/pack lobby | ✅ completed |
| 6 | [Tooling + Tests](phase-06-tooling-tests.md) | CLI commands, tests, docs (65 Python tests pass) | ✅ completed |

## Dependencies

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
                                                    Phase 6 depends on 3+4
```

## Key Decisions

- **Python 3.11+** for all pipeline scripts (no external AI API required for core)
- **No runtime generation** on device — puzzles pre-generated and bundled
- **Seed-based reproducibility** — same seed always yields same board
- **Offline-first** — pipeline has no network dependencies at run time
- **Existing iOS models enhanced** — add theme, pack, softHints; preserve backward compat
- **Board sizes**: 7×7 (mini), 9×9 (standard), 11×11 (extended)
- **V1 themes**: animals, food, fruits, sports, space, nature, ocean, city, school, travel, weather, music
- **License**: only MIT/Apache/CC0 sources shipped in app; build-time-only sources noted in LICENSE_NOTES.md

## Non-Goals (V1)

- No MCP, no live web crawler, no on-device generation
- No phrases with spaces/hyphens
- No online AI for gameplay
- No multiplayer, no cloud sync

## File Map

```
scripts/
├── fetch_wordlists.py        ← Phase 1: download/import source data
├── build_wordbank.py         ← Phase 1: normalize + score + export theme banks
├── build_clues.py            ← Phase 2: generate + score clues
├── generate_puzzle.py        ← Phase 3: single puzzle generation
├── generate_pack.py          ← Phase 4: pack generation
├── preview_puzzle.py         ← Phase 3: ASCII board preview
├── validate_outputs.py       ← Phase 4+6: validate pack JSON
└── run_pipeline.sh           ← Phase 6: end-to-end orchestration

pipeline/
├── __init__.py
├── config.py                 ← theme config loader
├── normalization.py          ← word normalization rules
├── scoring.py                ← popularity + crossword fit + theme fit scores
├── clue_templates.py         ← template-based clue generation
├── generator.py              ← crossword generator core
├── board.py                  ← board model + constraint validation
├── pack_builder.py           ← pack assembly
└── schema_validator.py       ← JSON schema validation

data/
├── raw/                      ← fetched source files
├── processed/                ← normalized per-theme
├── denylist.txt              ← profanity / unsafe words
├── allowlist.txt             ← custom approved overrides
└── clue-overrides.json       ← manual clue corrections

outputs/
├── wordbanks/<theme>.json
├── wordbanks/all.json
├── clues/<theme>.json
├── puzzles/<theme>/<difficulty>/<puzzleId>.json
└── packs/<packId>.json

SmartGames/Games/Crossword/
├── Models/
│   ├── CrosswordPuzzle.swift           ← MODIFY: add theme, softHints, packId
│   ├── CrosswordPack.swift             ← NEW: PuzzlePack model
│   └── CrosswordBoardState.swift       ← unchanged
├── Engine/
│   └── CrosswordPuzzleBank.swift       ← MODIFY: support pack-based loading
├── Views/
│   └── CrosswordLobbyView.swift        ← MODIFY: theme/pack selection
└── Resources/
    ├── crossword-packs-index.json      ← NEW: pack index
    └── crossword-pack-<id>.json        ← NEW: individual packs (replaces crossword-puzzles.json)
```

## What Still Needs Manual Review

- Clue quality: auto-generated clues need human spot-check before release
- Word appropriateness: denylist may miss regional slang
- Theme word assignment: some words may appear in wrong theme
- License attribution for each source dataset

## What Could Break

- BartMassey/wordlists: some lists may have changed URLs or formats
- imsky/wordlists: topic coverage varies by theme (some themes sparse)
- Frequency-based difficulty assumes English common usage — may penalize valid casual words
- Generator backtracking: dense boards (11×11) may timeout with small word banks

## V2 Improvements

- AI-assisted clue generation with offline LLM (Ollama)
- Phrase support (two-word answers)
- Dynamic daily puzzle sync from server
- User-submitted clue ratings feedback loop
- Harder generator with symmetry constraints
