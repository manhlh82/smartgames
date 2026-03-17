#!/usr/bin/env python3
"""Build per-theme word bank JSON files from downloaded raw word lists.

Usage:
    python3 scripts/build-wordbank.py [--theme <name>] [--dry-run]

Outputs:
    outputs/wordbanks/<theme>.json  — per-theme word entries
    outputs/wordbanks/all.json      — all themes merged
"""

import argparse
import json
import math
import sys
from pathlib import Path

# Allow importing pipeline package from repo root
REPO_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(REPO_ROOT))

from pipeline.config import load_config
from pipeline.models import WordEntry
from pipeline.normalization import normalize_word, is_valid_word
from pipeline.scoring import (
    compute_popularity,
    compute_crossword_fit,
    compute_theme_fit,
    assign_difficulty,
)

DATA_RAW = REPO_ROOT / "data" / "raw"
DATA_DIR = REPO_ROOT / "data"
OUTPUTS = REPO_ROOT / "outputs" / "wordbanks"

# ---------------------------------------------------------------------------
# Hardcoded fallback word lists for sparse themes (< 50 words from downloads)
# ---------------------------------------------------------------------------
SPARSE_FALLBACKS: dict[str, list[str]] = {
    "space": [
        "MOON", "STAR", "PLANET", "COMET", "ORBIT", "SOLAR", "NEBULA", "GALAXY",
        "ROCKET", "CRATER", "METEOR", "TITAN", "MARS", "VENUS", "SATURN", "COSMOS",
        "NOVA", "PULSAR", "QUASAR", "AURORA", "ZENITH", "ECLIPSE", "ASTEROID",
        "GRAVITY", "TELESCOPE", "PROBE", "LUNAR", "COSMIC", "SUNSPOT", "VORTEX",
    ],
    "school": [
        "BOOK", "DESK", "CLASS", "PENCIL", "RULER", "TEST", "EXAM", "GRADE",
        "LESSON", "STUDY", "TEACH", "LEARN", "MATH", "SCIENCE", "HISTORY", "ART",
        "GYM", "LIBRARY", "LUNCH", "RECESS", "DIPLOMA", "TUTOR", "ESSAY", "QUIZ",
        "NOTEBOOK", "CAMPUS", "DORM", "CHALK", "ERASER", "SYLLABUS",
    ],
    "weather": [
        "RAIN", "SNOW", "WIND", "CLOUD", "STORM", "FROST", "HAIL", "SLEET",
        "HUMID", "FOGGY", "SUNNY", "WARM", "COLD", "BREEZE", "THUNDER", "LIGHTNING",
        "RAINBOW", "DRIZZLE", "BLIZZARD", "TORNADO", "HURRICANE", "CYCLONE",
        "DROUGHT", "FLOOD", "MIST", "GALE", "SQUALL", "OVERCAST", "TEMPEST",
        "FORECAST",
    ],
    "city": [
        "ROAD", "PARK", "BRIDGE", "TOWER", "SUBWAY", "TAXI", "HOTEL", "MALL",
        "BANK", "STORE", "MARKET", "MUSEUM", "THEATER", "PLAZA", "AVENUE",
        "STREET", "ALLEY", "BLOCK", "DISTRICT", "URBAN", "METRO", "BUS", "TRAIN",
        "SKYSCRAPER", "TRAFFIC", "SIDEWALK", "PEDESTRIAN", "FOUNTAIN", "STATUE",
        "MONUMENT",
    ],
}

# imsky source category -> filesystem filename mapping
IMSKY_CATEGORY_MAP = {
    "imsky/animals": "animals",
    "imsky/dogs": "dogs",
    "imsky/cats": "cats",
    "imsky/birds": "birds",
    "imsky/foods": "foods",
    "imsky/vegetables": "vegetables",
    "imsky/fruits": "fruits",
    "imsky/fish": "fish",
    "imsky/astronomy": "astronomy",
    "imsky/plants": "plants",
    "imsky/flowers": "flowers",
    "imsky/trees": "trees",
    "imsky/sports": "sports",
    "imsky/music": "music",
    "imsky/transportation": "transportation",
    "imsky/geography": "geography",
    "imsky/education": "education",
    "imsky/weather": "weather",
}


def load_denylist(path: Path) -> set:
    if not path.exists():
        return set()
    return {line.strip().lower() for line in path.read_text().splitlines() if line.strip()}


def load_allowlist(path: Path) -> set:
    if not path.exists():
        return set()
    return {line.strip().lower() for line in path.read_text().splitlines() if line.strip()}


def load_freq_map(bartmassey_path: Path) -> dict[str, float]:
    """Parse BartMassey count_1w frequency file into normalized 0-1 scores.

    File format: word<TAB>count  (higher count = more common)
    Returns mapping of uppercase word -> score (1.0 = most common word).
    Only loads up to 50,000 entries for performance.
    """
    freq_map: dict[str, float] = {}
    if not bartmassey_path.exists():
        return freq_map

    lines = bartmassey_path.read_text(encoding="utf-8", errors="ignore").splitlines()
    entries = []
    for line in lines[:50000]:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) >= 2:
            try:
                word = parts[0].upper()
                count = int(parts[1])
                entries.append((word, count))
            except (ValueError, IndexError):
                continue

    if not entries:
        return freq_map

    # Use log-scale normalization so topic words (CAT, DOG, RAIN) score meaningfully.
    # Raw counts span many orders of magnitude; log brings them into a usable range.
    log_counts = [(word, math.log1p(count)) for word, count in entries]
    max_log = max(lc for _, lc in log_counts)
    for word, lc in log_counts:
        freq_map[word] = lc / max_log

    return freq_map


def load_imsky_words(source: str) -> list[str]:
    """Load raw words from an imsky category file. Returns empty list if missing."""
    category = IMSKY_CATEGORY_MAP.get(source)
    if not category:
        return []
    path = DATA_RAW / "imsky" / f"{category}.txt"
    if not path.exists():
        return []
    return [line.strip() for line in path.read_text(encoding="utf-8", errors="ignore").splitlines()
            if line.strip()]


def build_theme(
    theme_name: str,
    theme_cfg: dict,
    global_cfg: dict,
    denylist: set,
    allowlist: set,
    freq_map: dict,
) -> list[WordEntry]:
    """Build WordEntry list for a single theme."""
    min_len = theme_cfg.get("minLength", global_cfg["minLength"])
    max_len = theme_cfg.get("maxLength", global_cfg["maxLength"])

    seen: set[str] = set()
    entries: list[WordEntry] = []

    def process_word(raw: str, source: str, source_type: str) -> None:
        norm = normalize_word(raw)
        if norm is None:
            return
        if norm in seen:
            return

        valid, reason = is_valid_word(norm, denylist, allowlist, min_len, max_len)
        seen.add(norm)

        popularity = compute_popularity(norm, freq_map)
        cf_score = compute_crossword_fit(norm)
        tf_score = compute_theme_fit(norm, source_type)
        difficulty = assign_difficulty(popularity, cf_score)

        entries.append(WordEntry(
            word=norm,
            normalizedWord=norm,
            theme=theme_name,
            source=source,
            sourceType=source_type,
            difficulty=difficulty,
            popularityScore=round(popularity, 4),
            crosswordFitScore=round(cf_score, 4),
            themeFitScore=round(tf_score, 4),
            allowInGame=valid,
            bannedReason=reason,
            tags=[],
            clueCandidates=[],
            softHints={},
            notes="",
        ))

    # Load from imsky sources
    for source in theme_cfg.get("sources", []):
        raw_words = load_imsky_words(source)
        for word in raw_words:
            process_word(word, source, "topic_list")

    # Apply sparse fallback if fewer than 50 valid words loaded from files
    valid_count = sum(1 for e in entries if e.allowInGame)
    if valid_count < 50 and theme_name in SPARSE_FALLBACKS:
        for word in SPARSE_FALLBACKS[theme_name]:
            process_word(word, f"fallback/{theme_name}", "topic_list")

    return entries


def print_stats(theme_name: str, entries: list[WordEntry]) -> None:
    total = len(entries)
    valid = [e for e in entries if e.allowInGame]
    by_diff: dict[str, int] = {"easy": 0, "medium": 0, "hard": 0}
    for e in valid:
        by_diff[e.difficulty] = by_diff.get(e.difficulty, 0) + 1

    print(
        f"  {theme_name:<12}  total={total:>4}  valid={len(valid):>4}  "
        f"easy={by_diff['easy']:>3}  medium={by_diff['medium']:>3}  hard={by_diff['hard']:>3}"
    )


def write_wordbank(theme_name: str, entries: list[WordEntry], dry_run: bool) -> None:
    if dry_run:
        return
    OUTPUTS.mkdir(parents=True, exist_ok=True)
    out_path = OUTPUTS / f"{theme_name}.json"
    data = {
        "theme": theme_name,
        "count": len(entries),
        "words": [e.to_dict() for e in entries],
    }
    out_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build theme word banks")
    parser.add_argument("--theme", help="Build a single theme only")
    parser.add_argument("--dry-run", action="store_true", help="Show stats without writing files")
    args = parser.parse_args()

    cfg = load_config()
    global_cfg = cfg["global"]

    denylist = load_denylist(REPO_ROOT / global_cfg["denylistPath"])
    allowlist = load_allowlist(REPO_ROOT / global_cfg["allowlistPath"])
    freq_map = load_freq_map(DATA_RAW / "bartmassey" / "count_1w.txt")

    if freq_map:
        print(f"Loaded frequency map: {len(freq_map)} entries")
    else:
        print("No frequency map found — using default popularity 0.5")

    themes = cfg["themes"]
    if args.theme:
        if args.theme not in themes:
            print(f"ERROR: Theme '{args.theme}' not found in config")
            sys.exit(1)
        themes = {args.theme: themes[args.theme]}

    if args.dry_run:
        print("(dry-run mode — no files will be written)\n")

    print(f"\nBuilding {len(themes)} theme(s)...\n")

    all_entries: list[WordEntry] = []

    for theme_name, theme_cfg in themes.items():
        entries = build_theme(theme_name, theme_cfg, global_cfg, denylist, allowlist, freq_map)
        print_stats(theme_name, entries)
        write_wordbank(theme_name, entries, dry_run=args.dry_run)
        all_entries.extend(entries)

    # Write merged all.json
    if not args.dry_run and not args.theme:
        OUTPUTS.mkdir(parents=True, exist_ok=True)
        all_path = OUTPUTS / "all.json"
        all_data = {
            "count": len(all_entries),
            "words": [e.to_dict() for e in all_entries],
        }
        all_path.write_text(json.dumps(all_data, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"\nWrote outputs/wordbanks/all.json  ({len(all_entries)} total entries)")

    total_valid = sum(1 for e in all_entries if e.allowInGame)
    print(f"\nDone. Total entries: {len(all_entries)}  Valid: {total_valid}")


if __name__ == "__main__":
    main()
