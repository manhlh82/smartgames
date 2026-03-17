# Pipeline Dictionary Overhaul — Implementation Report

**Date:** 2026-03-18
**Status:** completed

---

## Files Modified

| File | Change |
|------|--------|
| `pipeline/models.py` | Added `wordSource`, `licenseNotes` to `WordEntry`; added `clueSource`, `sourceDefinition`, `clueGenerationMethod`, `licenseNotes`, `needsReview` to `ClueEntry`; updated both `to_dict()` |
| `pipeline/pack_builder.py` | Added `_GENERIC_CLUE_PREFIXES`, added `strict_clues` param to `validate_puzzle`, added clue quality block; updated `validate_pack` to pass `strict_clues=True` |
| `scripts/build-clues.py` | Replaced `clue_templates` import with `clue_generator` + `dictionary`; loads lookup at startup; warns if empty; tracks `dictionary_clue`/`needs_review`/`override` counts; updated summary output |
| `scripts/generate-pack.py` | Replaced `clue_templates` import with `clue_generator` + `dictionary`; `load_word_bank` now excludes `needsReview` words from clue file; `load_clue_map` uses `make_clue_entry`; added `_get_lookup()` singleton |
| `scripts/build-wordbank.py` | `load_imsky_words` now returns `(words, word_source_path)`; `process_word` accepts `word_source_path`; `WordEntry` created with `wordSource` and `licenseNotes="MIT"` |
| `.gitignore` | Added `data/raw/kaikki/` to exclude 2.5GB raw JSONL |

## Files Created

| File | Purpose |
|------|---------|
| `pipeline/dictionary.py` | `build_lookup()` streams Kaikki JSONL → compact JSON; `load_lookup()` loads compiled lookup; gracefully returns `{}` if file missing |
| `pipeline/clue_generator.py` | `clean_gloss()` strips wiki markup/parentheticals, truncates, rejects self-ref/generic; `make_clue_entry()` implements override → dict → needs_review priority |
| `scripts/fetch-dictionary.py` | Downloads Kaikki `.jsonl.gz`, decompresses, calls `build_lookup()`; idempotent |

---

## Tasks Completed

- [x] `WordEntry` provenance fields (`wordSource`, `licenseNotes`) with defaults
- [x] `ClueEntry` provenance fields (`clueSource`, `sourceDefinition`, `clueGenerationMethod`, `licenseNotes`, `needsReview`) with defaults
- [x] Both `to_dict()` updated
- [x] `pipeline/dictionary.py` created — `build_lookup` + `load_lookup`
- [x] `pipeline/clue_generator.py` created — `clean_gloss`, `generate_clue_from_dict`, `make_clue_entry`
- [x] `scripts/fetch-dictionary.py` created — download + decompress + build_lookup
- [x] `scripts/build-clues.py` updated — uses new generator, warns on empty lookup, tracks new breakdown counts
- [x] `pipeline/pack_builder.py` updated — `validate_puzzle` with `strict_clues` param, generic clue detection
- [x] `scripts/generate-pack.py` updated — filters needsReview words pre-generation, uses `make_clue_entry` for auto-generated clues
- [x] `scripts/build-wordbank.py` updated — `wordSource` provenance from actual imsky file paths
- [x] `.gitignore` updated — excludes `data/raw/kaikki/`

---

## Tests Status

- **Unit tests:** 65/65 passed (`python3 -m pytest tests/ -v`)
- **Models test:** `ClueEntry` and `WordEntry` have all new provenance fields in `to_dict()` output
- **Clue cleaning:** wiki markup stripped, self-referential clues rejected (None), too-short generic rejected (None)
- **Dictionary load:** returns `{}` gracefully when lookup file absent
- **build-clues.py (no dict):** warns correctly, marks all 71 ocean words as `needs_review`, does not crash
- **make_clue_entry:** all 3 paths work — override, dictionary_gloss, needs_review
- **validate_puzzle:** generic clues (`found in...`) caught in strict mode; empty clues caught; valid clues pass

---

## Notes

- `clue_templates.py` kept as-is (not removed) — `generate_clue` still imported in `scripts/generate-pack.py` was replaced; checked no other imports remain. The file itself is kept for backward compat in case external scripts use it.
- `data/raw/` is already in `.gitignore`; added explicit `data/raw/kaikki/` entry as well for clarity.
- Kaikki download NOT performed — file is 2.5GB; pipeline handles missing lookup gracefully.
- `build-clues.py` now always applies overrides when `--apply-overrides` flag is set; the previous behavior was the same.

---

## Unresolved Questions

None.
