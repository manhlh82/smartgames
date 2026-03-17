#!/usr/bin/env python3
"""ASCII preview of a generated crossword puzzle.

Usage:
    python3 scripts/preview-puzzle.py <puzzle_json_path>

Prints the solution grid with cell numbers, then ACROSS and DOWN clue lists.
"""

import json
import sys
from pathlib import Path


def load_puzzle(path: str) -> dict:
    p = Path(path)
    if not p.exists():
        print(f"Error: file not found: {path}", file=sys.stderr)
        sys.exit(1)
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def build_number_grid(puzzle: dict) -> list[list[int]]:
    """Build a grid of word-start numbers (0 = no number)."""
    rows, cols = puzzle["rows"], puzzle["cols"]
    num_grid = [[0] * cols for _ in range(rows)]
    for entry in puzzle["entries"]:
        num_grid[entry["row"]][entry["col"]] = entry["number"]
    return num_grid


def render_grid(puzzle: dict) -> list[str]:
    """Render solution grid as lines of text."""
    rows, cols = puzzle["rows"], puzzle["cols"]
    solution = puzzle["solutionGrid"]
    num_grid = build_number_grid(puzzle)

    cell_w = 4  # width per cell: "A  " with number superscript
    lines: list[str] = []

    # Column header
    col_header = "     " + "".join(f"{c:<{cell_w}}" for c in range(1, cols + 1))
    lines.append(col_header)
    lines.append("     " + "-" * (cols * cell_w))

    for r in range(rows):
        row_parts: list[str] = []
        for c in range(cols):
            letter = solution[r][c]
            num = num_grid[r][c]
            if not letter:
                # Black/empty cell
                cell = "."
            elif num:
                # Show number superscript inline: "1A" style
                cell = f"{num}{letter}"
            else:
                cell = letter
            row_parts.append(f"{cell:<{cell_w}}")
        lines.append(f"{r + 1:>3}  {''.join(row_parts)}")

    return lines


def render_clues(puzzle: dict) -> list[str]:
    """Render ACROSS and DOWN clue lists."""
    lines: list[str] = []

    for direction in ("across", "down"):
        lines.append(f"\n{direction.upper()}:")
        clue_group = puzzle.get("clueGroups", {}).get(direction, [])
        if not clue_group:
            lines.append("  (none)")
            continue
        for item in sorted(clue_group, key=lambda x: x["number"]):
            num    = item["number"]
            clue   = item["clue"] or "(no clue)"
            length = item["length"]
            lines.append(f"  {num:>3}. {clue} ({length})")

    return lines


def render_stats(puzzle: dict) -> list[str]:
    stats = puzzle.get("stats", {})
    meta  = puzzle.get("uiMetadata", {})
    return [
        "",
        f"Puzzle : {puzzle.get('puzzleId', '?')}",
        f"Theme  : {puzzle.get('theme')} | Difficulty: {puzzle.get('difficulty')} | "
        f"Size: {meta.get('boardSize', '?')} ({puzzle['rows']}x{puzzle['cols']})",
        f"Words  : {stats.get('wordCount', '?')} | "
        f"Intersections: {stats.get('intersections', '?')} | "
        f"Score: {stats.get('boardScore', '?')}",
        f"Seed   : {puzzle.get('seed')}",
    ]


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: preview-puzzle.py <puzzle_json_path>", file=sys.stderr)
        sys.exit(1)

    puzzle = load_puzzle(sys.argv[1])

    for line in render_stats(puzzle):
        print(line)

    print()
    for line in render_grid(puzzle):
        print(line)

    for line in render_clues(puzzle):
        print(line)


if __name__ == "__main__":
    main()
