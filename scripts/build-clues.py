#!/usr/bin/env python3
"""Build clue files for all themes or a specific theme.

Usage:
    python3 scripts/build-clues.py [--theme THEME] [--show-flagged] [--apply-overrides]

For each word in outputs/wordbanks/<theme>.json:
  1. Check data/clue-overrides.json for manual override
  2. Kaikki dictionary lookup → clean gloss
  3. Mark as needs_review if no definition found
  4. Write to outputs/clues/<theme>.json
"""

import argparse
import json
import sys
from pathlib import Path

# Ensure project root is on path
ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT))

from pipeline.clue_generator import make_clue_entry
from pipeline.dictionary import build_lookup_for_words, load_lookup, KAIKKI_RAW_PATH, LOOKUP_PATH

WORDBANKS_DIR = ROOT / "outputs" / "wordbanks"
CLUES_DIR = ROOT / "outputs" / "clues"
OVERRIDES_PATH = ROOT / "data" / "clue-overrides.json"


def load_overrides() -> dict:
    """Load clue-overrides.json; return empty dict if missing or invalid."""
    if not OVERRIDES_PATH.exists():
        return {}
    try:
        with open(OVERRIDES_PATH, encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}


def process_theme(
    theme: str,
    overrides: dict,
    apply_overrides: bool,
    show_flagged: bool,
    lookup: dict,
) -> dict:
    """Process one theme's wordbank into a clues output file.

    Returns summary stats dict with keys:
      theme, total, flagged, dictionary_clue, needs_review, override
    """
    wordbank_path = WORDBANKS_DIR / f"{theme}.json"
    if not wordbank_path.exists():
        print(f"  [SKIP] wordbank not found: {wordbank_path}")
        return {
            "theme": theme, "total": 0, "flagged": 0,
            "dictionary_clue": 0, "needs_review": 0, "override": 0,
        }

    with open(wordbank_path, encoding="utf-8") as f:
        bank = json.load(f)

    words: list[dict] = bank.get("words", [])
    clue_entries: list[dict] = []
    counts = {"dictionary_clue": 0, "needs_review": 0, "override": 0}
    flagged_words: list[str] = []

    for word_entry in words:
        if not word_entry.get("allowInGame", True):
            continue

        word = word_entry["word"].upper()
        difficulty = word_entry.get("difficulty", "medium")
        word_source = word_entry.get("wordSource", "")

        # Determine override for this word (only if apply_overrides flag set)
        override = overrides.get(word) if apply_overrides else None

        clue_entry = make_clue_entry(
            word=word,
            theme=theme,
            difficulty=difficulty,
            lookup=lookup,
            word_source=word_source,
            override=override,
        )

        # Track source breakdown
        clue_source = clue_entry.get("clueSource", "")
        if clue_source == "override":
            counts["override"] += 1
        elif clue_entry.get("needsReview", False):
            counts["needs_review"] += 1
        else:
            counts["dictionary_clue"] += 1

        clue_entries.append(clue_entry)

        if clue_entry.get("reviewFlags"):
            flagged_words.append(word)

    # Write output
    CLUES_DIR.mkdir(parents=True, exist_ok=True)
    output_path = CLUES_DIR / f"{theme}.json"
    output = {
        "theme": theme,
        "count": len(clue_entries),
        "clues": clue_entries,
    }
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    total = len(clue_entries)
    flagged_count = len(flagged_words)

    print(
        f"  {theme}: {total} words | flagged={flagged_count} | "
        f"override={counts['override']} dictionary={counts['dictionary_clue']} "
        f"needs_review={counts['needs_review']}"
    )

    if show_flagged and flagged_words:
        for w in flagged_words:
            print(f"    [flagged] {w}")

    return {
        "theme": theme,
        "total": total,
        "flagged": flagged_count,
        **counts,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Build clue files for crossword themes.")
    parser.add_argument("--theme", help="Process a single theme only (e.g. ocean)")
    parser.add_argument("--show-flagged", action="store_true", help="Print flagged words per theme")
    parser.add_argument(
        "--apply-overrides",
        action="store_true",
        help="Apply manual clue overrides from data/clue-overrides.json",
    )
    args = parser.parse_args()

    # Collect accepted words from word banks (used for focused dictionary lookup)
    bank_files = (
        [WORDBANKS_DIR / f"{args.theme}.json"] if args.theme
        else [p for p in WORDBANKS_DIR.glob("*.json") if p.stem != "all"]
    )
    accepted_words: set[str] = set()
    for bf in bank_files:
        if bf.exists():
            with open(bf, encoding="utf-8") as f:
                bank = json.load(f)
            for w in bank.get("words", []):
                if w.get("allowInGame", True):
                    accepted_words.add(w["word"].upper())

    # Build focused lookup from Kaikki if raw data is available; else load existing
    if KAIKKI_RAW_PATH.exists():
        print(f"Building focused dictionary lookup for {len(accepted_words)} words …")
        found = build_lookup_for_words(accepted_words)
        print(f"Lookup built: {found}/{len(accepted_words)} words found in Kaikki data")
        lookup = load_lookup()
    else:
        lookup = load_lookup()
        if lookup:
            print(f"Loaded existing dictionary: {len(lookup)} words from data/kaikki-lookup.json")
        else:
            print(
                "WARNING: No dictionary loaded. Run fetch-dictionary.py first. "
                "Words will be marked needs_review."
            )

    overrides = load_overrides() if args.apply_overrides else {}
    if args.apply_overrides:
        print(f"Loaded {len(overrides)} clue overrides.")

    # Determine themes to process
    if args.theme:
        themes = [args.theme]
    else:
        themes = sorted(
            p.stem for p in WORDBANKS_DIR.glob("*.json") if p.stem != "all"
        )

    print(f"\nProcessing {len(themes)} theme(s)...\n")
    all_stats = []
    for theme in themes:
        stats = process_theme(
            theme=theme,
            overrides=overrides,
            apply_overrides=args.apply_overrides,
            show_flagged=args.show_flagged,
            lookup=lookup,
        )
        all_stats.append(stats)

    # Summary
    total_words = sum(s["total"] for s in all_stats)
    total_flagged = sum(s["flagged"] for s in all_stats)
    total_override = sum(s["override"] for s in all_stats)
    total_dictionary = sum(s["dictionary_clue"] for s in all_stats)
    total_needs_review = sum(s["needs_review"] for s in all_stats)

    print(f"\nSummary: {total_words} total words across {len(themes)} theme(s)")
    print(f"  Flagged      : {total_flagged}")
    print(f"  Override     : {total_override}")
    print(f"  Dictionary   : {total_dictionary}")
    print(f"  Needs review : {total_needs_review}")
    print(f"\nClue files written to: {CLUES_DIR}/")


if __name__ == "__main__":
    main()
