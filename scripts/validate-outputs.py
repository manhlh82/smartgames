#!/usr/bin/env python3
"""Standalone validator for generated pack JSON files.

Loads all pack JSON files from outputs/packs/, runs validate_pack() on each,
prints PASS/FAIL per pack, and exits with code 1 if any FAIL.

Usage:
    python3 scripts/validate-outputs.py
    python3 scripts/validate-outputs.py --pack animals-easy
"""

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT))

from pipeline.pack_builder import validate_pack

PACKS_DIR = ROOT / "outputs" / "packs"


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate generated pack JSON files.")
    parser.add_argument("--pack", metavar="PACK_ID",
                        help="Validate a single pack by ID (default: all)")
    args = parser.parse_args()

    if not PACKS_DIR.exists():
        print(f"Error: packs directory not found: {PACKS_DIR}", file=sys.stderr)
        sys.exit(1)

    if args.pack:
        pack_files = [PACKS_DIR / f"{args.pack}.json"]
        missing = [p for p in pack_files if not p.exists()]
        if missing:
            print(f"Error: pack file not found: {missing[0]}", file=sys.stderr)
            sys.exit(1)
    else:
        pack_files = sorted(PACKS_DIR.glob("*.json"))

    if not pack_files:
        print(f"No pack files found in {PACKS_DIR}")
        sys.exit(0)

    print(f"Validating {len(pack_files)} pack(s) from {PACKS_DIR.relative_to(ROOT)}/\n")

    fail_count = 0
    pass_count = 0

    for pack_path in pack_files:
        pack_id = pack_path.stem
        try:
            with open(pack_path, encoding="utf-8") as f:
                pack = json.load(f)
        except json.JSONDecodeError as e:
            print(f"  [FAIL] {pack_id}: JSON parse error — {e}")
            fail_count += 1
            continue

        errors = validate_pack(pack)
        puzzle_count = len(pack.get("puzzles", []))

        if errors:
            print(f"  [FAIL] {pack_id} ({puzzle_count} puzzles):")
            for err in errors:
                print(f"         - {err}")
            fail_count += 1
        else:
            print(f"  [PASS] {pack_id} ({puzzle_count} puzzles)")
            pass_count += 1

    print(f"\nResult: {pass_count} PASS, {fail_count} FAIL out of {len(pack_files)} pack(s)")

    if fail_count > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
