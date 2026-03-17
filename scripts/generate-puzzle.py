#!/usr/bin/env python3
"""Generate a single crossword puzzle for a given theme, difficulty, and board size.

Usage:
    python3 scripts/generate-puzzle.py --theme THEME --difficulty DIFFICULTY \
        --size SIZE --seed SEED [--count N] [--overwrite]
"""

import argparse
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT))

from pipeline.generator import CrosswordGenerator, BOARD_SIZE_CONFIG

WORDBANKS_DIR = ROOT / "outputs" / "wordbanks"
CLUES_DIR     = ROOT / "outputs" / "clues"
PUZZLES_DIR   = ROOT / "outputs" / "puzzles"


def load_word_bank(theme: str) -> list[dict]:
    path = WORDBANKS_DIR / f"{theme}.json"
    if not path.exists():
        raise FileNotFoundError(f"Word bank not found: {path}")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data.get("words", [])


def load_clue_map(theme: str) -> dict[str, dict]:
    """Load clues/<theme>.json and return word -> ClueEntry dict mapping."""
    path = CLUES_DIR / f"{theme}.json"
    if not path.exists():
        return {}
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return {entry["word"]: entry for entry in data.get("clues", [])}


def generate_one(
    theme: str,
    difficulty: str,
    board_size: str,
    seed: int,
    word_bank: list[dict],
    clue_map: dict[str, dict],
    overwrite: bool,
) -> dict | None:
    cfg = BOARD_SIZE_CONFIG[board_size]
    rows, cols = cfg["rows"], cfg["cols"]
    puzzle_id = f"{theme}-{difficulty}-{rows}x{cols}-{seed:04d}"
    out_path = PUZZLES_DIR / theme / difficulty / f"{puzzle_id}.json"

    if out_path.exists() and not overwrite:
        print(f"  [SKIP] {puzzle_id} already exists (use --overwrite to regenerate)")
        with open(out_path, encoding="utf-8") as f:
            return json.load(f)

    gen = CrosswordGenerator()
    t0 = time.monotonic()
    puzzle = gen.generate(
        theme=theme,
        difficulty=difficulty,
        board_size=board_size,
        seed=seed,
        word_bank=word_bank,
        clue_map=clue_map,
        max_restarts=20,
        timeout_seconds=30.0,
    )
    elapsed = time.monotonic() - t0

    if puzzle is None:
        print(f"  [FAIL] {puzzle_id} — not enough words placed")
        return None

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(puzzle, f, indent=2, ensure_ascii=False)

    stats = puzzle.get("stats", {})
    print(
        f"  [OK] {puzzle_id} — words={stats.get('wordCount')}, "
        f"intersections={stats.get('intersections')}, "
        f"score={stats.get('boardScore'):.4f}, "
        f"time={elapsed:.2f}s → {out_path.relative_to(ROOT)}"
    )
    return puzzle


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate crossword puzzle(s).")
    parser.add_argument("--theme",      required=True, help="Theme name (e.g. ocean)")
    parser.add_argument("--difficulty", required=True, choices=["easy", "medium", "hard"])
    parser.add_argument("--size",       required=True, choices=list(BOARD_SIZE_CONFIG),
                        help="Board size: mini | standard | extended")
    parser.add_argument("--seed",       required=True, type=int, help="RNG seed")
    parser.add_argument("--count",      type=int, default=1,
                        help="Number of puzzles to generate (seeds: seed, seed+1, …)")
    parser.add_argument("--overwrite",  action="store_true",
                        help="Overwrite existing puzzle files")
    args = parser.parse_args()

    word_bank = load_word_bank(args.theme)
    clue_map  = load_clue_map(args.theme)

    if not clue_map:
        print(f"Warning: no clue file found for '{args.theme}'. "
              "Run build-clues.py first for better clues.")

    print(f"Generating {args.count} puzzle(s): theme={args.theme} "
          f"difficulty={args.difficulty} size={args.size} seed={args.seed}\n")

    success = 0
    for i in range(args.count):
        puzzle = generate_one(
            theme=args.theme,
            difficulty=args.difficulty,
            board_size=args.size,
            seed=args.seed + i,
            word_bank=word_bank,
            clue_map=clue_map,
            overwrite=args.overwrite,
        )
        if puzzle:
            success += 1

    print(f"\nDone: {success}/{args.count} generated successfully.")


if __name__ == "__main__":
    main()
