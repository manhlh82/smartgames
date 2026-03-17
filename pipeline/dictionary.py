"""
Dictionary lookup module using Kaikki.org (Wiktionary extract) data.

Kaikki provides Wiktionary in JSONL format (one JSON object per line).
Build-time only — raw data and compiled lookup are never committed or shipped.

Workflow:
  1. python3 scripts/fetch-dictionary.py   # download Kaikki once (~2.5GB)
  2. python3 scripts/build-clues.py        # streams Kaikki, extracts only accepted themed words
  3. python3 scripts/generate-pack.py --all  # uses clues to build iOS pack assets

The lookup at data/kaikki-lookup.json is a build artifact: it contains only the
~900 accepted themed words (not all English), is generated fresh each pipeline run,
and is excluded from git.
"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).parent.parent
KAIKKI_RAW_PATH = ROOT / "data" / "raw" / "kaikki" / "raw-wiktextract-data.jsonl"
LOOKUP_PATH = ROOT / "data" / "kaikki-lookup.json"


def build_lookup_for_words(
    word_set: set[str],
    source_path: Path = KAIKKI_RAW_PATH,
    out_path: Path = LOOKUP_PATH,
) -> int:
    """Stream Kaikki JSONL and extract glosses only for words in word_set.

    This produces a compact lookup (~900 entries) instead of scanning all English.
    Stops streaming early once all words in word_set are found.

    Returns count of words found.
    """
    if not source_path.exists():
        raise FileNotFoundError(
            f"Kaikki data not found at {source_path}. Run fetch-dictionary.py first."
        )

    remaining = {w.upper() for w in word_set}
    lookup: dict[str, list[str]] = {}

    with open(source_path, encoding="utf-8") as f:
        for line in f:
            if not remaining:
                break  # found all words — stop early
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            if entry.get("lang_code") != "en":
                continue

            pos = entry.get("pos", "")
            if pos not in ("noun", "adj", "verb"):
                continue

            word = entry.get("word", "").upper().strip()
            if word not in remaining:
                continue

            glosses: list[str] = []
            for sense in entry.get("senses", []):
                for gloss in sense.get("glosses", []):
                    if gloss and len(gloss) > 5:
                        glosses.append(gloss)
                        if len(glosses) >= 3:
                            break
                if len(glosses) >= 3:
                    break

            if glosses:
                glosses.sort(key=len)
                lookup[word] = glosses[:3]
                remaining.discard(word)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(lookup, f, ensure_ascii=False)

    return len(lookup)


def build_lookup(
    source_path: Path = KAIKKI_RAW_PATH,
    out_path: Path = LOOKUP_PATH,
    max_words: int = None,
) -> int:
    """Stream full Kaikki JSONL and build broad word→glosses lookup.

    Use build_lookup_for_words() instead for pipeline runs (much faster).
    This full-scan variant is kept for tooling/debugging purposes.
    """
    if not source_path.exists():
        raise FileNotFoundError(
            f"Kaikki data not found at {source_path}. Run fetch-dictionary.py first."
        )

    lookup: dict[str, list[str]] = {}
    count = 0

    with open(source_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            if entry.get("lang_code") != "en":
                continue
            if entry.get("pos", "") not in ("noun", "adj", "verb"):
                continue

            word = entry.get("word", "").upper().strip()
            if not re.match(r'^[A-Z]{3,12}$', word):
                continue

            glosses: list[str] = []
            for sense in entry.get("senses", []):
                for gloss in sense.get("glosses", []):
                    if gloss and len(gloss) > 5:
                        glosses.append(gloss)
                        if len(glosses) >= 3:
                            break
                if len(glosses) >= 3:
                    break

            if not glosses:
                continue

            glosses.sort(key=len)
            if word not in lookup:
                lookup[word] = glosses[:3]

            count += 1
            if max_words and count >= max_words:
                break

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(lookup, f, ensure_ascii=False)

    return len(lookup)


def load_lookup(path: Path = LOOKUP_PATH) -> dict:
    """Load the compiled lookup dict. Returns empty dict if not found."""
    if not path.exists():
        return {}
    with open(path, encoding="utf-8") as f:
        return json.load(f)
