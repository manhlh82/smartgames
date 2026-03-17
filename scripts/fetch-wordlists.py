#!/usr/bin/env python3
"""Download word lists from GitHub raw URLs into data/raw/.

Usage:
    python3 scripts/fetch-wordlists.py

Idempotent: skips files that already exist.
Handles 404s and network errors gracefully (warns and continues).
"""

import gzip
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path

# Resolve repo root relative to this script
REPO_ROOT = Path(__file__).parent.parent
DATA_RAW = REPO_ROOT / "data" / "raw"

# ---------------------------------------------------------------------------
# imsky/wordlists — files live under nouns/ with slightly different names
# Mapping: logical name -> actual filename in the repo
# ---------------------------------------------------------------------------
IMSKY_BASE = "https://raw.githubusercontent.com/imsky/wordlists/master/nouns"
IMSKY_CATEGORIES = [
    # (logical_name, actual_filename_in_repo)
    ("animals", "apex_predators"),      # closest general "animals" list available
    ("dogs", "dogs"),
    ("cats", "cats"),
    ("birds", "birds"),
    ("foods", "food"),
    ("vegetables", "seasonings"),       # best available proxy for vegetables/food
    ("fruits", "fruit"),
    ("fish", "fish"),
    ("astronomy", "astronomy"),
    ("plants", "plants"),
    ("flowers", "plants"),              # no dedicated flowers file; reuse plants
    ("trees", "plants"),                # no dedicated trees file; reuse plants
    ("sports", "sports"),
    ("music", "music_instruments"),
    ("transportation", "automobiles"),  # closest transportation proxy
    ("geography", "geography"),
    ("education", "coding"),            # no education file; use coding as proxy
    ("weather", "water"),               # no weather file; use water as proxy
]

# ---------------------------------------------------------------------------
# BartMassey/wordlists — frequency list (gzipped, word\tcount format)
# ---------------------------------------------------------------------------
BARTMASSEY_FILES = [
    (
        "https://raw.githubusercontent.com/BartMassey/wordlists/master/count_1w.txt.gz",
        "bartmassey/count_1w.txt.gz",
    ),
]


def download_file(url: str, dest: Path, decompress_gz: bool = False) -> bool:
    """Download url to dest. Returns True on success, False on failure.

    If decompress_gz=True and the URL ends in .gz, decompresses to dest
    (dest path should NOT have the .gz extension).
    """
    dest.parent.mkdir(parents=True, exist_ok=True)

    if dest.exists():
        print(f"  [skip]  {dest.relative_to(REPO_ROOT)}  (already exists)")
        return True

    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "smartgames-pipeline/1.0"},
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()

        if decompress_gz and url.endswith(".gz"):
            content = gzip.decompress(raw)
        else:
            content = raw

        dest.write_bytes(content)
        line_count = content.count(b"\n")
        print(f"  [ok]    {dest.relative_to(REPO_ROOT)}  ({line_count} lines)")
        return True
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"  [warn]  {url}  -> 404 Not Found, skipping")
        else:
            print(f"  [warn]  {url}  -> HTTP {e.code}, skipping")
        return False
    except Exception as e:
        print(f"  [warn]  {url}  -> {e}, skipping")
        return False


def fetch_imsky() -> tuple[int, int]:
    """Fetch all imsky category files. Returns (ok, skipped_or_failed)."""
    print("\n--- imsky/wordlists ---")
    ok = skipped = 0
    for logical_name, repo_filename in IMSKY_CATEGORIES:
        url = f"{IMSKY_BASE}/{repo_filename}.txt"
        # Save under logical name so the rest of the pipeline uses consistent names
        dest = DATA_RAW / "imsky" / f"{logical_name}.txt"
        success = download_file(url, dest)
        if success:
            ok += 1
        else:
            skipped += 1
    return ok, skipped


def fetch_bartmassey() -> tuple[int, int]:
    """Fetch BartMassey frequency files. Returns (ok, skipped_or_failed)."""
    print("\n--- BartMassey/wordlists ---")
    ok = skipped = 0
    for url, rel_path in BARTMASSEY_FILES:
        # Decompress .gz on the fly; save without .gz extension
        dest_rel = rel_path.replace(".gz", "")
        dest = DATA_RAW / dest_rel
        success = download_file(url, dest, decompress_gz=True)
        if success:
            ok += 1
        else:
            skipped += 1
    return ok, skipped


def main() -> None:
    print(f"Fetching word lists into: {DATA_RAW}")
    DATA_RAW.mkdir(parents=True, exist_ok=True)

    imsky_ok, imsky_fail = fetch_imsky()
    bart_ok, bart_fail = fetch_bartmassey()

    total_ok = imsky_ok + bart_ok
    total_fail = imsky_fail + bart_fail

    print(f"\n=== Summary ===")
    print(f"  Downloaded / already-present : {total_ok}")
    print(f"  Skipped / failed             : {total_fail}")

    if total_fail > 0:
        print("  (Some files unavailable — pipeline will use fallback words for sparse themes)")


if __name__ == "__main__":
    main()
