"""
Pack assembly, validation, and file writing for the crossword content pipeline.
Handles building Pack and PacksIndex dicts and writing them to outputs/.
"""

import json
import os
from datetime import date
from pathlib import Path


def load_pack_definitions(path="pipeline/pack_definitions.json") -> list[dict]:
    """Load pack definitions from JSON file."""
    with open(path, encoding="utf-8") as f:
        return json.load(f)


_GENERIC_CLUE_PREFIXES = (
    "a type of", "a kind of", "found in", "related to", "something you",
)


def validate_puzzle(puzzle: dict, strict_clues: bool = True) -> list[str]:
    """Validate a single puzzle dict. Returns list of error strings (empty = valid).

    Checks:
    - entries not empty
    - all entries have non-empty clue
    - all entries have softHints with startsWith, length, category
    - solutionGrid dimensions match rows x cols
    - each entry answer matches solutionGrid letters at position
    - direction is 'across' or 'down'
    - (strict_clues=True) clue quality: no empty or generic clues
    """
    errors = []
    entries = puzzle.get("entries", [])

    if not entries:
        errors.append(f"puzzle '{puzzle.get('puzzleId')}': entries is empty")
        return errors

    rows = puzzle.get("rows", 0)
    cols = puzzle.get("cols", 0)
    solution = puzzle.get("solutionGrid", [])

    # Validate solutionGrid dimensions
    if len(solution) != rows:
        errors.append(
            f"puzzle '{puzzle.get('puzzleId')}': solutionGrid has {len(solution)} rows, expected {rows}"
        )
    else:
        for r_idx, row in enumerate(solution):
            if len(row) != cols:
                errors.append(
                    f"puzzle '{puzzle.get('puzzleId')}': solutionGrid row {r_idx} has {len(row)} cols, expected {cols}"
                )

    # Clue quality check (strict mode)
    if strict_clues:
        for entry in puzzle.get("entries", []):
            clue = entry.get("clue", "").strip()
            answer = entry.get("answer", "")
            if not clue:
                errors.append(f"Entry {answer} has empty clue")
            elif clue.lower().startswith(_GENERIC_CLUE_PREFIXES):
                errors.append(f"Entry {answer} has generic clue: '{clue}'")

    for entry in entries:
        word = entry.get("answer", "")
        direction = entry.get("direction", "")
        row = entry.get("row", 0)
        col = entry.get("col", 0)
        clue = entry.get("clue", "")
        soft_hints = entry.get("softHints", {})
        entry_id = f"entry#{entry.get('number')} '{word}'"

        # Check non-empty clue
        if not clue or not clue.strip():
            errors.append(f"puzzle '{puzzle.get('puzzleId')}' {entry_id}: clue is empty")

        # Check direction
        if direction not in ("across", "down"):
            errors.append(
                f"puzzle '{puzzle.get('puzzleId')}' {entry_id}: invalid direction '{direction}'"
            )

        # Check softHints has required keys
        for key in ("startsWith", "length", "category"):
            if key not in soft_hints:
                errors.append(
                    f"puzzle '{puzzle.get('puzzleId')}' {entry_id}: softHints missing '{key}'"
                )

        # Validate answer matches solutionGrid letters at position
        if solution and direction in ("across", "down") and word:
            for i, ch in enumerate(word):
                if direction == "across":
                    r, c = row, col + i
                else:
                    r, c = row + i, col

                if r < len(solution) and c < len(solution[r]):
                    grid_ch = solution[r][c]
                    # Grid may use "#" for black squares or " " for blanks
                    if grid_ch not in ("#", " ", "") and grid_ch != ch:
                        errors.append(
                            f"puzzle '{puzzle.get('puzzleId')}' {entry_id}: "
                            f"answer[{i}]='{ch}' but solutionGrid[{r}][{c}]='{grid_ch}'"
                        )

    return errors


def validate_pack(pack: dict) -> list[str]:
    """Validate a pack dict. Returns list of error strings (empty = valid).

    Checks:
    - puzzleCount matches len(puzzles)
    - no duplicate puzzleId within pack
    - each puzzle passes validate_puzzle()
    """
    errors = []
    pack_id = pack.get("packId", "<unknown>")
    puzzles = pack.get("puzzles", [])
    declared_count = pack.get("puzzleCount", 0)

    if len(puzzles) != declared_count:
        errors.append(
            f"pack '{pack_id}': puzzleCount={declared_count} but contains {len(puzzles)} puzzles"
        )

    # Check for duplicate puzzleIds
    seen_ids: set[str] = set()
    for puzzle in puzzles:
        pid = puzzle.get("puzzleId", "")
        if pid in seen_ids:
            errors.append(f"pack '{pack_id}': duplicate puzzleId '{pid}'")
        seen_ids.add(pid)

    # Validate each puzzle
    for puzzle in puzzles:
        errors.extend(validate_puzzle(puzzle, strict_clues=True))

    return errors


def build_pack(pack_def: dict, puzzles: list[dict], version: str = "1.0.0") -> dict:
    """Assemble a pack dict from a definition + list of puzzle dicts."""
    return {
        "packId": pack_def["packId"],
        "title": pack_def["title"],
        "theme": pack_def["theme"],
        "difficulty": pack_def["difficulty"],
        "boardSize": pack_def["boardSize"],
        "puzzleCount": len(puzzles),
        "version": version,
        "createdAt": date.today().isoformat(),
        "puzzles": puzzles,
    }


def write_pack(pack: dict, output_dir: str = "outputs/packs") -> Path:
    """Write pack to outputs/packs/<packId>.json. Returns written path."""
    out_dir = Path(output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{pack['packId']}.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(pack, f, indent=2, ensure_ascii=False)
    return out_path


def build_packs_index(packs_meta: list[dict], version: str = "1.0.0") -> dict:
    """Build a PacksIndex dict from a list of pack metadata dicts."""
    return {
        "version": version,
        "generatedAt": date.today().isoformat(),
        "packs": packs_meta,
    }


def write_packs_index(index: dict, output_path: str = "outputs/packs-index.json") -> Path:
    """Write packs index to JSON file. Returns written path."""
    out_path = Path(output_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(index, f, indent=2, ensure_ascii=False)
    return out_path
