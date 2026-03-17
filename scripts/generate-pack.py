#!/usr/bin/env python3
"""Generate crossword packs from pack definitions.

Usage:
    python3 scripts/generate-pack.py --all
    python3 scripts/generate-pack.py --pack animals-easy
    python3 scripts/generate-pack.py --all --validate-only
"""

import argparse
import json
import sys
import time
from itertools import cycle
from pathlib import Path

ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT))

from pipeline.clue_templates import generate_clue
from pipeline.generator import CrosswordGenerator
from pipeline.pack_builder import (
    build_pack,
    build_packs_index,
    load_pack_definitions,
    validate_pack,
    write_pack,
    write_packs_index,
)

WORDBANKS_DIR = ROOT / "outputs" / "wordbanks"
CLUES_DIR     = ROOT / "outputs" / "clues"
PACKS_DIR     = ROOT / "outputs" / "packs"
INDEX_PATH    = ROOT / "outputs" / "packs-index.json"

# Themes to cycle through for "mixed" packs
MIXED_THEMES = ["animals", "food", "ocean", "space", "nature"]

# Max attempts per puzzle slot (seed offsets: 0, 100, 200, 300, 400)
MAX_ATTEMPTS = 5
SEED_OFFSET   = 100


# Minimum word count before supplementing with all.json fallback
_MIN_WORD_BANK_SIZE = 80

# Cached all.json fallback words (loaded once on demand)
_all_words_cache: list[dict] | None = None


def _load_all_words() -> list[dict]:
    """Load the all.json word bank once and cache it."""
    global _all_words_cache
    if _all_words_cache is None:
        path = WORDBANKS_DIR / "all.json"
        if path.exists():
            with open(path, encoding="utf-8") as f:
                _all_words_cache = json.load(f).get("words", [])
        else:
            _all_words_cache = []
    return _all_words_cache


def load_word_bank(theme: str) -> list[dict]:
    """Load theme word bank. If fewer than _MIN_WORD_BANK_SIZE words, supplement with all.json."""
    path = WORDBANKS_DIR / f"{theme}.json"
    if not path.exists():
        raise FileNotFoundError(f"Word bank not found: {path}")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    words = data.get("words", [])

    if len(words) < _MIN_WORD_BANK_SIZE:
        theme_word_set = {w["word"] for w in words}
        fallback = [w for w in _load_all_words() if w["word"] not in theme_word_set]
        words = words + fallback

    return words


def load_clue_map(theme: str, word_bank: list[dict] | None = None) -> dict[str, dict]:
    """Load clues/<theme>.json and return word -> ClueEntry dict mapping.

    If word_bank is provided, auto-generate clue entries for any words not
    already covered by the theme clue file (needed when word bank is supplemented
    from all.json fallback).
    """
    path = CLUES_DIR / f"{theme}.json"
    clue_map: dict[str, dict] = {}

    if path.exists():
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        for entry in data.get("clues", []):
            clue_map[entry["word"]] = entry

    # Auto-generate entries for any words in the word bank not in the clue map
    if word_bank:
        for word_entry in word_bank:
            word = word_entry.get("word", "")
            if word and word not in clue_map:
                # Use word's own theme if available, else fall back to pack theme
                word_theme = word_entry.get("theme", theme) or theme
                clue_map[word] = generate_clue(word_entry, word_theme)

    return clue_map


def generate_puzzle_with_retries(
    gen: CrosswordGenerator,
    theme: str,
    difficulty: str,
    board_size: str,
    base_seed: int,
    word_bank: list[dict],
    clue_map: dict[str, dict],
) -> dict | None:
    """Try up to MAX_ATTEMPTS seeds (offset by SEED_OFFSET each) to get a valid puzzle."""
    for attempt in range(MAX_ATTEMPTS):
        seed = base_seed + attempt * SEED_OFFSET
        puzzle = gen.generate(
            theme=theme,
            difficulty=difficulty,
            board_size=board_size,
            seed=seed,
            word_bank=word_bank,
            clue_map=clue_map,
            max_restarts=5,
            timeout_seconds=15.0,
        )
        if puzzle is not None:
            return puzzle
    return None


def generate_pack(pack_def: dict, validate_only: bool = False) -> dict | None:
    """Generate all puzzles for a pack and return the assembled pack dict.

    For validate_only mode: loads existing pack file if it exists.
    Returns None if generation fully failed or pack file missing in validate_only mode.
    """
    pack_id = pack_def["packId"]
    theme = pack_def["theme"]
    difficulty = pack_def["difficulty"]
    board_size = pack_def["boardSize"]
    target_count = pack_def["puzzleCount"]

    # validate-only: load existing pack file
    if validate_only:
        pack_path = PACKS_DIR / f"{pack_id}.json"
        if not pack_path.exists():
            print(f"  [SKIP] {pack_id}: no pack file found at {pack_path}")
            return None
        with open(pack_path, encoding="utf-8") as f:
            return json.load(f)

    print(f"\n[PACK] {pack_id} — theme={theme} difficulty={difficulty} "
          f"size={board_size} target={target_count}")

    gen = CrosswordGenerator()
    puzzles: list[dict] = []
    t0 = time.monotonic()

    # For mixed theme: cycle through MIXED_THEMES
    if theme == "mixed":
        theme_cycle = cycle(MIXED_THEMES)
        # Pre-load all theme word banks / clue maps to avoid repeated disk I/O
        theme_banks: dict[str, list[dict]] = {}
        theme_clues: dict[str, dict] = {}
        for t in MIXED_THEMES:
            try:
                wb = load_word_bank(t)
                theme_banks[t] = wb
                theme_clues[t] = load_clue_map(t, wb)
            except FileNotFoundError as e:
                print(f"  [WARN] {e} — skipping theme '{t}' in mixed pack")

        for i in range(target_count):
            actual_theme = next(theme_cycle)
            # Skip themes with no word bank
            attempts_to_find_theme = 0
            while actual_theme not in theme_banks and attempts_to_find_theme < len(MIXED_THEMES):
                actual_theme = next(theme_cycle)
                attempts_to_find_theme += 1

            if actual_theme not in theme_banks:
                print(f"  [WARN] puzzle {i+1}: no valid mixed theme available, skipping")
                continue

            wb = theme_banks[actual_theme]
            cm = theme_clues.get(actual_theme, {})
            base_seed = i + 1

            puzzle = generate_puzzle_with_retries(
                gen, actual_theme, difficulty, board_size, base_seed, wb, cm
            )
            if puzzle is None:
                print(f"  [WARN] puzzle {i+1} (theme={actual_theme}): failed after {MAX_ATTEMPTS} attempts, skipping")
            else:
                puzzles.append(puzzle)
                stats = puzzle.get("stats", {})
                print(f"  [{len(puzzles):02d}/{target_count}] {puzzle['puzzleId']} "
                      f"words={stats.get('wordCount')} score={stats.get('boardScore'):.3f}")
    else:
        # Single-theme pack
        try:
            word_bank = load_word_bank(theme)
            clue_map = load_clue_map(theme, word_bank)
        except FileNotFoundError as e:
            print(f"  [ERROR] {e}")
            return None

        for i in range(target_count):
            base_seed = i + 1
            puzzle = generate_puzzle_with_retries(
                gen, theme, difficulty, board_size, base_seed, word_bank, clue_map
            )
            if puzzle is None:
                print(f"  [WARN] puzzle {i+1}: failed after {MAX_ATTEMPTS} attempts, skipping")
            else:
                puzzles.append(puzzle)
                stats = puzzle.get("stats", {})
                print(f"  [{len(puzzles):02d}/{target_count}] {puzzle['puzzleId']} "
                      f"words={stats.get('wordCount')} score={stats.get('boardScore'):.3f}")

    elapsed = time.monotonic() - t0

    if len(puzzles) < target_count:
        print(f"  [WARN] pack '{pack_id}': generated {len(puzzles)}/{target_count} puzzles")

    pack = build_pack(pack_def, puzzles)
    print(f"  => {len(puzzles)} puzzles assembled in {elapsed:.1f}s")
    return pack


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate crossword packs.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--pack",  metavar="PACK_ID", help="Generate a single pack by ID")
    group.add_argument("--all",   action="store_true", help="Generate all packs")
    parser.add_argument("--validate-only", action="store_true",
                        help="Skip generation; validate existing pack files only")
    args = parser.parse_args()

    pack_defs = load_pack_definitions(str(ROOT / "pipeline" / "pack_definitions.json"))

    # Filter to requested pack(s)
    if args.pack:
        matching = [p for p in pack_defs if p["packId"] == args.pack]
        if not matching:
            ids = [p["packId"] for p in pack_defs]
            print(f"Error: pack '{args.pack}' not found. Available: {ids}", file=sys.stderr)
            sys.exit(1)
        selected = matching
    else:
        selected = pack_defs

    total_start = time.monotonic()
    packs_meta: list[dict] = []
    results: list[tuple[str, str]] = []  # (packId, "PASS"|"FAIL"|"SKIP")

    for pack_def in selected:
        pack_id = pack_def["packId"]
        pack = generate_pack(pack_def, validate_only=args.validate_only)

        if pack is None:
            results.append((pack_id, "SKIP"))
            continue

        # Validate
        errors = validate_pack(pack)
        if errors:
            print(f"  [VALIDATION ERRORS] pack '{pack_id}':")
            for err in errors:
                print(f"    - {err}")
            results.append((pack_id, "FAIL"))
        else:
            results.append((pack_id, "PASS"))

        # Write pack file (skip in validate-only mode)
        if not args.validate_only:
            out_path = write_pack(pack, str(PACKS_DIR))
            print(f"  [WRITE] {out_path.relative_to(ROOT)}")

        # Collect metadata for index
        packs_meta.append({
            "packId": pack["packId"],
            "title": pack["title"],
            "theme": pack["theme"],
            "difficulty": pack["difficulty"],
            "boardSize": pack["boardSize"],
            "puzzleCount": pack["puzzleCount"],
            "resourceFile": f"packs/{pack['packId']}.json",
            "isUnlocked": pack_def.get("isUnlocked", True),
            "createdAt": pack.get("createdAt", ""),
            "version": pack.get("version", "1.0.0"),
        })

    # Build and write packs index (skip in validate-only mode)
    if packs_meta and not args.validate_only:
        index = build_packs_index(packs_meta)
        idx_path = write_packs_index(index, str(INDEX_PATH))
        print(f"\n[INDEX] Written to {idx_path.relative_to(ROOT)}")

    # Summary
    total_elapsed = time.monotonic() - total_start
    print(f"\n{'='*60}")
    print(f"Summary ({total_elapsed:.1f}s total):")
    for pack_id, status in results:
        icon = "OK" if status == "PASS" else ("--" if status == "SKIP" else "!!")
        print(f"  [{icon}] {pack_id}: {status}")

    fail_count = sum(1 for _, s in results if s == "FAIL")
    pass_count = sum(1 for _, s in results if s == "PASS")
    skip_count = sum(1 for _, s in results if s == "SKIP")
    print(f"\n  PASS={pass_count}  FAIL={fail_count}  SKIP={skip_count}")

    if fail_count > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
