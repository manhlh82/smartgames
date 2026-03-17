"""Tests for pipeline.pack_builder — validate_puzzle and validate_pack."""

from pipeline.pack_builder import validate_puzzle, validate_pack


def _make_valid_puzzle(puzzle_id="test-001"):
    """Build a minimal valid 3x5 puzzle dict by hand."""
    # Place "CAT" across at row 1, col 1
    solution = [
        ["", "", "", "", ""],
        ["", "C", "A", "T", ""],
        ["", "", "", "", ""],
    ]
    return {
        "puzzleId": puzzle_id,
        "rows": 3,
        "cols": 5,
        "solutionGrid": solution,
        "entries": [
            {
                "number": 1,
                "answer": "CAT",
                "direction": "across",
                "row": 1,
                "col": 1,
                "length": 3,
                "clue": "Furry pet",
                "softHints": {
                    "startsWith": "C",
                    "length": 3,
                    "category": "animals",
                },
                "theme": "animals",
                "difficulty": "easy",
            }
        ],
    }


def _make_valid_pack(pack_id="test-pack", n=2):
    puzzles = [_make_valid_puzzle(f"test-{i:03d}") for i in range(n)]
    return {
        "packId": pack_id,
        "title": "Test Pack",
        "theme": "animals",
        "difficulty": "easy",
        "boardSize": "mini",
        "puzzleCount": n,
        "version": "1.0.0",
        "createdAt": "2026-01-01",
        "puzzles": puzzles,
    }


class TestValidatePuzzle:
    def test_valid_puzzle_no_errors(self):
        errors = validate_puzzle(_make_valid_puzzle())
        assert errors == []

    def test_empty_entries_returns_error(self):
        puzzle = _make_valid_puzzle()
        puzzle["entries"] = []
        errors = validate_puzzle(puzzle)
        assert len(errors) > 0
        assert any("entries" in e for e in errors)

    def test_answer_mismatch_returns_error(self):
        puzzle = _make_valid_puzzle()
        # Corrupt the solutionGrid so it disagrees with the entry answer
        puzzle["solutionGrid"][1][1] = "X"  # was "C"
        errors = validate_puzzle(puzzle)
        assert len(errors) > 0
        assert any("solutionGrid" in e or "answer" in e for e in errors)

    def test_empty_clue_returns_error(self):
        puzzle = _make_valid_puzzle()
        puzzle["entries"][0]["clue"] = ""
        errors = validate_puzzle(puzzle)
        assert any("clue" in e for e in errors)

    def test_invalid_direction_returns_error(self):
        puzzle = _make_valid_puzzle()
        puzzle["entries"][0]["direction"] = "diagonal"
        errors = validate_puzzle(puzzle)
        assert any("direction" in e for e in errors)

    def test_missing_soft_hint_key_returns_error(self):
        puzzle = _make_valid_puzzle()
        del puzzle["entries"][0]["softHints"]["startsWith"]
        errors = validate_puzzle(puzzle)
        assert any("softHints" in e or "startsWith" in e for e in errors)

    def test_grid_row_count_mismatch_returns_error(self):
        puzzle = _make_valid_puzzle()
        puzzle["rows"] = 5  # actual grid only has 3 rows
        errors = validate_puzzle(puzzle)
        assert any("rows" in e or "solutionGrid" in e for e in errors)


class TestValidatePack:
    def test_valid_pack_no_errors(self):
        errors = validate_pack(_make_valid_pack())
        assert errors == []

    def test_puzzle_count_mismatch_returns_error(self):
        pack = _make_valid_pack(n=2)
        pack["puzzleCount"] = 5  # wrong count
        errors = validate_pack(pack)
        assert any("puzzleCount" in e for e in errors)

    def test_duplicate_puzzle_ids_returns_error(self):
        pack = _make_valid_pack(n=2)
        # Force both puzzles to have same ID
        pack["puzzles"][0]["puzzleId"] = "dupe-id"
        pack["puzzles"][1]["puzzleId"] = "dupe-id"
        errors = validate_pack(pack)
        assert any("duplicate" in e.lower() or "dupe-id" in e for e in errors)

    def test_invalid_puzzle_inside_pack_surfaces_error(self):
        pack = _make_valid_pack(n=1)
        pack["puzzles"][0]["entries"] = []  # invalid puzzle
        errors = validate_pack(pack)
        assert len(errors) > 0
