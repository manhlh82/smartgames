# Phase Implementation Report

## Executed Phase
- Phase: Phase 6 — Tooling, Tests, Dev Experience
- Plan: plans/260317-2006-crossword-pipeline (crossword content pipeline)
- Status: completed

## Files Modified / Created

| File | Lines | Action |
|------|-------|--------|
| `scripts/run-pipeline.sh` | 14 | created, chmod +x |
| `requirements.txt` | 2 | created |
| `tests/__init__.py` | 0 | created (empty) |
| `tests/test_normalization.py` | 72 | created |
| `tests/test_scoring.py` | 63 | created |
| `tests/test_board.py` | 95 | created |
| `tests/test_generator.py` | 103 | created |
| `tests/test_pack_validation.py` | 110 | created |
| `scripts/README.md` | 67 | created |
| `TROUBLESHOOTING.md` | 34 | created |

## Tasks Completed

- [x] `scripts/run-pipeline.sh` — full pipeline runner with iOS copy step, made executable
- [x] `requirements.txt` — `pytest>=7.0` only (pydantic not used)
- [x] `tests/__init__.py` — empty package marker
- [x] `tests/test_normalization.py` — 12 normalize_word + 6 is_valid_word tests
- [x] `tests/test_scoring.py` — 5 crossword_fit + 4 theme_fit + 6 assign_difficulty tests
- [x] `tests/test_board.py` — 7 placement + 2 numbering + 4 export tests
- [x] `tests/test_generator.py` — 3 determinism + 5 output-shape tests (loads real ocean data)
- [x] `tests/test_pack_validation.py` — 7 validate_puzzle + 4 validate_pack tests (hand-built fixtures)
- [x] `scripts/README.md` — quick start, individual steps, options, adding themes, clue override
- [x] `TROUBLESHOOTING.md` — 4 common failure scenarios with remediation steps

## Tests Status

- Unit tests: **65 passed, 0 failed** (python3 -m pytest tests/ -v)
- Type check: n/a (Python, no mypy configured)

## Issues Encountered

- Pytest does not discover `test-*.py` (hyphenated) files — renamed all to `test_*.py` (underscore). The naming guidance says kebab-case for Python but pytest's discovery protocol requires `test_*.py`; test files follow pytest convention.
- Word bank and clue JSON files use a wrapper dict (`{"theme":…,"words":[…]}` and `{"theme":…,"clues":[…]}`), not bare lists. Generator expects a list for `word_bank` and a word-keyed dict for `clue_map`. Fixed in test fixture: unwrap `words` key, build dict from clues list.

## Next Steps

- Docs impact: minor — `scripts/README.md` added; `docs/codebase-summary.md` may want a note about the pipeline test suite
- Pipeline is now fully runnable end-to-end via `bash scripts/run-pipeline.sh`
- CI: consider adding `python3 -m pytest tests/` as a pre-commit or GitHub Actions step
