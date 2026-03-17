#!/usr/bin/env python3
"""
Download Kaikki.org English Wiktionary extract and build compact word lookup.

Build-time only — output is never committed or shipped in the app.
Final app assets are only the generated puzzle/clue packs in outputs/packs/.

Usage:
    python3 scripts/fetch-dictionary.py [--build-only] [--full]

  --build-only  Skip download; rebuild lookup from already-downloaded JSONL
  --full        Build lookup for all English words (slow); default builds only
                for the accepted themed words from outputs/wordbanks/

Steps:
  1. Download kaikki.org English extract (~2.5GB .gz) — idempotent
  2. Decompress to data/raw/kaikki/raw-wiktextract-data.jsonl
  3. Stream JSONL, extract definitions only for accepted themed words
  4. Write compact lookup to data/kaikki-lookup.json (~900 entries, a few KB)

After running this, re-run build-clues.py to generate real definition-based clues.
"""

import argparse
import gzip
import json
import shutil
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT))

from pipeline.dictionary import build_lookup, build_lookup_for_words, KAIKKI_RAW_PATH

# Current English extract URL from kaikki.org
KAIKKI_URL = "https://kaikki.org/dictionary/English/kaikki.org-dictionary-English.jsonl.gz"
GZ_PATH = KAIKKI_RAW_PATH.with_suffix(".jsonl.gz")


def download_kaikki(out_gz: Path) -> None:
    """Download Kaikki English extract with progress indicator."""
    out_gz.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {KAIKKI_URL} → {out_gz}")
    print("This is ~1.5–2.5GB. May take several minutes.")

    def progress(block_num: int, block_size: int, total_size: int) -> None:
        downloaded = block_num * block_size
        if total_size > 0:
            pct = min(100, downloaded * 100 // total_size)
            mb = downloaded / 1_000_000
            print(f"\r  {pct}% ({mb:.1f} MB)", end="", flush=True)

    urllib.request.urlretrieve(KAIKKI_URL, out_gz, reporthook=progress)
    print()


def decompress_kaikki(gz_path: Path, out_path: Path) -> None:
    """Decompress .gz to .jsonl."""
    print(f"Decompressing {gz_path.name} …")
    with gzip.open(gz_path, 'rb') as f_in, open(out_path, 'wb') as f_out:
        shutil.copyfileobj(f_in, f_out)
    print(f"Decompressed → {out_path}")


def collect_accepted_words() -> set[str]:
    """Collect all accepted words from built word banks."""
    wordbanks_dir = ROOT / "outputs" / "wordbanks"
    words: set[str] = set()
    for bank_file in wordbanks_dir.glob("*.json"):
        if bank_file.stem == "all":
            continue
        with open(bank_file, encoding="utf-8") as f:
            bank = json.load(f)
        for entry in bank.get("words", []):
            if entry.get("allowInGame", True):
                words.add(entry["word"].upper())
    return words


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch Kaikki dictionary and build word lookup")
    parser.add_argument(
        "--build-only",
        action="store_true",
        help="Skip download, just rebuild lookup from existing JSONL",
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help="Build lookup for all English words (slow); default: only accepted themed words",
    )
    args = parser.parse_args()

    if not args.build_only:
        if KAIKKI_RAW_PATH.exists():
            size_mb = KAIKKI_RAW_PATH.stat().st_size // 1_000_000
            print(f"JSONL already exists ({size_mb} MB). Skipping download.")
        else:
            if not GZ_PATH.exists():
                download_kaikki(GZ_PATH)
            else:
                print(".gz already downloaded. Decompressing...")
            decompress_kaikki(GZ_PATH, KAIKKI_RAW_PATH)

    if args.full:
        print("Building full English lookup (slow) …")
        count = build_lookup()
        print(f"Full lookup built: {count} words → data/kaikki-lookup.json")
    else:
        word_set = collect_accepted_words()
        if not word_set:
            print("WARNING: No accepted words found. Run build-wordbank.py first.")
            return
        print(f"Building focused lookup for {len(word_set)} accepted themed words …")
        count = build_lookup_for_words(word_set)
        print(f"Focused lookup built: {count}/{len(word_set)} words found → data/kaikki-lookup.json")


if __name__ == "__main__":
    main()
