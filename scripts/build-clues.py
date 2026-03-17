#!/usr/bin/env python3
"""Build clue files for all themes or a specific theme.

Usage:
    python3 scripts/build-clues.py [--theme THEME] [--show-flagged] [--apply-overrides]

For each word in outputs/wordbanks/<theme>.json:
  1. Check data/clue-overrides.json for manual override
  2. Else use clueCandidates if present
  3. Else use template from clue_templates
  4. Write to outputs/clues/<theme>.json
"""

import argparse
import json
import sys
from pathlib import Path

# Ensure project root is on path
ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT))

from pipeline.clue_templates import generate_clue

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


def build_clue_entry_with_override(
    word_entry: dict,
    theme: str,
    overrides: dict,
    apply_overrides: bool,
) -> tuple[dict, str]:
    """Build a ClueEntry dict for word_entry, applying override if available.

    Returns (clue_entry_dict, source_label) where source_label is one of
    'override', 'candidates', 'template'.
    """
    word = word_entry["word"].upper()

    if apply_overrides and word in overrides:
        override = overrides[word]
        clue_entry = {
            "word": word,
            "primaryClue": override.get("primaryClue", ""),
            "alternateClues": override.get("alternateClues", []),
            "softHints": {
                "startsWith": word[0],
                "length": len(word),
                "category": theme,
            },
            "difficulty": word_entry.get("difficulty", "medium"),
            "source": "override",
            "reviewFlags": [],
            "approved": True,
        }
        return clue_entry, "override"

    clue_entry = generate_clue(word_entry, theme)

    if word_entry.get("clueCandidates"):
        source_label = "candidates"
    else:
        source_label = "template"

    return clue_entry, source_label


def process_theme(
    theme: str,
    overrides: dict,
    apply_overrides: bool,
    show_flagged: bool,
) -> dict:
    """Process one theme's wordbank into a clues output file.

    Returns summary stats dict.
    """
    wordbank_path = WORDBANKS_DIR / f"{theme}.json"
    if not wordbank_path.exists():
        print(f"  [SKIP] wordbank not found: {wordbank_path}")
        return {"theme": theme, "total": 0, "flagged": 0, "override": 0, "candidates": 0, "template": 0}

    with open(wordbank_path, encoding="utf-8") as f:
        bank = json.load(f)

    words: list[dict] = bank.get("words", [])
    clue_entries: list[dict] = []
    counts = {"override": 0, "candidates": 0, "template": 0}
    flagged_words: list[str] = []

    for word_entry in words:
        if not word_entry.get("allowInGame", True):
            continue

        clue_entry, source_label = build_clue_entry_with_override(
            word_entry, theme, overrides, apply_overrides
        )
        counts[source_label] += 1
        clue_entries.append(clue_entry)

        if clue_entry.get("reviewFlags"):
            flagged_words.append(clue_entry["word"])

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

    print(f"  {theme}: {total} words | flagged={flagged_count} | "
          f"override={counts['override']} candidates={counts['candidates']} template={counts['template']}")

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
    parser.add_argument("--apply-overrides", action="store_true", help="Apply manual clue overrides from data/clue-overrides.json")
    args = parser.parse_args()

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

    print(f"Processing {len(themes)} theme(s)...\n")
    all_stats = []
    for theme in themes:
        stats = process_theme(
            theme=theme,
            overrides=overrides,
            apply_overrides=args.apply_overrides,
            show_flagged=args.show_flagged,
        )
        all_stats.append(stats)

    # Summary
    total_words = sum(s["total"] for s in all_stats)
    total_flagged = sum(s["flagged"] for s in all_stats)
    total_override = sum(s["override"] for s in all_stats)
    total_candidates = sum(s["candidates"] for s in all_stats)
    total_template = sum(s["template"] for s in all_stats)

    print(f"\nSummary: {total_words} total words across {len(themes)} theme(s)")
    print(f"  Flagged   : {total_flagged}")
    print(f"  Override  : {total_override}")
    print(f"  Candidates: {total_candidates}")
    print(f"  Template  : {total_template}")
    print(f"\nClue files written to: {CLUES_DIR}/")


if __name__ == "__main__":
    main()
