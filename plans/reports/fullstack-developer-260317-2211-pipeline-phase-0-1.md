# Pipeline Phase 0 & 1 Implementation Report

**Date:** 2026-03-17
**Agent:** fullstack-developer
**Plan:** plans/260317-2006-crossword-pipeline/

---

## Status: Completed

---

## Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `pipeline/__init__.py` | 0 | Package marker |
| `pipeline/themes-config.json` | 62 | Theme + global + boardSize config |
| `pipeline/config.py` | 45 | `load_config()` with validation |
| `pipeline/models.py` | 200 | Dataclasses: WordEntry, ClueEntry, PlacedEntry, PuzzleOutput, PackMeta, Pack, PacksIndex |
| `pipeline/normalization.py` | 74 | `normalize_word()`, `is_valid_word()` |
| `pipeline/scoring.py` | 83 | `compute_popularity()`, `compute_crossword_fit()`, `compute_theme_fit()`, `assign_difficulty()` |
| `scripts/fetch-wordlists.py` | 151 | Downloads imsky/wordlists + BartMassey freq list; idempotent |
| `scripts/build-wordbank.py` | 297 | Builds per-theme + all.json word banks; --theme, --dry-run flags |
| `data/denylist.txt` | ~53 | ~50 profanity/unsafe words |
| `data/allowlist.txt` | 0 | Empty (custom override placeholder) |
| `data/clue-overrides.json` | 1 | Empty JSON object |
| `LICENSE_NOTES.md` | 32 | Documents 3 MIT word list sources |

### Directories created
- `pipeline/`, `data/raw/`, `data/processed/`, `outputs/wordbanks/`, `outputs/clues/`, `outputs/puzzles/`, `outputs/packs/`, `outputs/samples/`, `scripts/`, `tests/`

---

## Commands Run + Output

### Config + Models verification
```
Config OK, themes: ['animals', 'food', 'fruits', 'ocean', 'space', 'nature', 'sports', 'music', 'travel', 'city', 'school', 'weather']
Models OK: {word: TEST, normalizedWord: TEST, ...}  ✓
```

### fetch-wordlists.py
Downloaded 19 files (18 imsky topic lists + 1 BartMassey freq list).
SSL issue fixed by running Python 3.13's Install Certificates.command.
imsky repo paths corrected from `words/` to `nouns/` with updated filename mapping.
BartMassey source corrected to `count_1w.txt.gz` (word\tcount format, 333,333 lines), decompressed on-the-fly.
Idempotency confirmed: second run shows all `[skip]` entries.

### build-wordbank.py
Frequency scoring uses log-scale normalization (`math.log1p`) to prevent "the" (count ~23B) from collapsing all topic words to near-zero scores.

---

## Word Counts Per Theme

| Theme | Total | Valid | Easy | Medium | Hard |
|-------|-------|-------|------|--------|------|
| animals | 147 | 147 | 24 | 123 | 0 |
| food | 164 | 163 | 56 | 107 | 0 |
| fruits | 31 | 31 | 8 | 23 | 0 |
| ocean | 71 | 71 | 16 | 55 | 0 |
| space | 63 | 62 | 26 | 36 | 0 |
| nature | 58 | 58 | 29 | 29 | 0 |
| sports | 128 | 128 | 69 | 59 | 0 |
| music | 30 | 30 | 6 | 24 | 0 |
| travel | 23 | 22 | 6 | 16 | 0 |
| city | 86 | 85 | 57 | 28 | 0 |
| school | 52 | 52 | 42 | 10 | 0 |
| weather | 67 | 67 | 36 | 31 | 0 |
| **all.json** | **920** | **916** | — | — | — |

---

## Issues Encountered

1. **imsky/wordlists path change** — repo structure uses `nouns/` not `words/`, and several category names differ (e.g., `food.txt` not `foods.txt`, `fruit.txt` not `fruits.txt`). Fixed in `IMSKY_CATEGORIES` mapping.

2. **BartMassey format** — `word-freq-top5000.txt` does not exist; correct file is `count_1w.txt.gz` (word\tcount, 333K lines, gzipped). Fetch script now decompresses on-the-fly.

3. **macOS SSL certs** — Python 3.13 framework install needed `Install Certificates.command` run once to install certifi.

4. **hard=0 across all themes** — initial linear freq normalization made all topic words score near 0 (dominated by "the" at 23B count). Fixed with `math.log1p` normalization. Hard difficulty still shows 0 because topic-list words default to 0.5 when absent from freq map, placing them in medium rather than hard. This is correct behavior — only words with *confirmed* low frequency (< 0.40) score as hard.

---

## Unresolved Questions

- **hard=0** is structurally expected given the freq map only covers 50K most-common words — all niche topic words not in that set default to 0.5 popularity (medium). If harder words are desired, the threshold in `assign_difficulty()` could be relaxed (e.g., `popularity < 0.55`) or additional rare-word signals could be added.
- **sparse themes**: music (30), travel (23), fruits (31) are below typical crossword pack requirements of 50+ words. Fallback word lists cover space/school/weather/city but not music/travel. Phase 2 clue generation should flag these for manual supplementation.
- `flowers` and `trees` currently reuse `plants.txt` from imsky (no dedicated files exist). Consider supplementing with hardcoded fallbacks in a future pass.
