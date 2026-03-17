"""Tests for pipeline.generator.CrosswordGenerator — determinism and output shape."""

import json
import os
import pytest
from pipeline.generator import CrosswordGenerator

# Load real ocean word bank and clue map once at module level
_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_WORDBANK_PATH = os.path.join(_REPO_ROOT, "outputs", "wordbanks", "ocean.json")
_CLUES_PATH = os.path.join(_REPO_ROOT, "outputs", "clues", "ocean.json")


def _load_ocean_data():
    with open(_WORDBANK_PATH, encoding="utf-8") as f:
        raw_wb = json.load(f)
    # Wordbank JSON has wrapper: {"theme": ..., "count": ..., "words": [...]}
    word_bank = raw_wb["words"] if isinstance(raw_wb, dict) and "words" in raw_wb else raw_wb

    with open(_CLUES_PATH, encoding="utf-8") as f:
        raw_clues = json.load(f)
    # Clues JSON has wrapper: {"theme": ..., "count": ..., "clues": [...]}
    # Generator expects a dict keyed by word: {"WHALE": {"primaryClue": ..., ...}}
    clues_list = raw_clues["clues"] if isinstance(raw_clues, dict) and "clues" in raw_clues else raw_clues
    clue_map = {entry["word"]: entry for entry in clues_list} if isinstance(clues_list, list) else raw_clues

    return word_bank, clue_map


@pytest.fixture(scope="module")
def ocean_data():
    return _load_ocean_data()


@pytest.fixture(scope="module")
def generator():
    return CrosswordGenerator()


class TestGeneratorDeterminism:
    def test_same_seed_same_puzzle_id(self, generator, ocean_data):
        word_bank, clue_map = ocean_data
        p1 = generator.generate("ocean", "medium", "standard", 42, word_bank, clue_map)
        p2 = generator.generate("ocean", "medium", "standard", 42, word_bank, clue_map)
        assert p1 is not None
        assert p2 is not None
        assert p1["puzzleId"] == p2["puzzleId"]

    def test_same_seed_same_entry_count(self, generator, ocean_data):
        word_bank, clue_map = ocean_data
        p1 = generator.generate("ocean", "medium", "standard", 7, word_bank, clue_map)
        p2 = generator.generate("ocean", "medium", "standard", 7, word_bank, clue_map)
        assert p1 is not None
        assert p2 is not None
        assert len(p1["entries"]) == len(p2["entries"])

    def test_different_seeds_may_differ(self, generator, ocean_data):
        word_bank, clue_map = ocean_data
        p1 = generator.generate("ocean", "medium", "standard", 1, word_bank, clue_map)
        p2 = generator.generate("ocean", "medium", "standard", 999, word_bank, clue_map)
        # Not guaranteed to differ, but puzzleIds encode seed so they must differ
        assert p1 is not None
        assert p2 is not None
        assert p1["puzzleId"] != p2["puzzleId"]


class TestGeneratorOutputShape:
    def test_standard_9x9_dimensions(self, generator, ocean_data):
        word_bank, clue_map = ocean_data
        puzzle = generator.generate("ocean", "medium", "standard", 42, word_bank, clue_map)
        assert puzzle is not None
        assert puzzle["rows"] == 9
        assert puzzle["cols"] == 9

    def test_minimum_entry_count(self, generator, ocean_data):
        word_bank, clue_map = ocean_data
        puzzle = generator.generate("ocean", "medium", "standard", 42, word_bank, clue_map)
        assert puzzle is not None
        assert len(puzzle["entries"]) >= 4

    def test_entries_have_clue_and_answer(self, generator, ocean_data):
        word_bank, clue_map = ocean_data
        puzzle = generator.generate("ocean", "medium", "standard", 42, word_bank, clue_map)
        assert puzzle is not None
        for entry in puzzle["entries"]:
            assert "clue" in entry
            assert "answer" in entry
            assert isinstance(entry["answer"], str)
            assert len(entry["answer"]) > 0

    def test_solution_grid_matches_dimensions(self, generator, ocean_data):
        word_bank, clue_map = ocean_data
        puzzle = generator.generate("ocean", "medium", "standard", 42, word_bank, clue_map)
        assert puzzle is not None
        grid = puzzle["solutionGrid"]
        assert len(grid) == puzzle["rows"]
        for row in grid:
            assert len(row) == puzzle["cols"]

    def test_returns_none_for_empty_word_bank(self, generator):
        puzzle = generator.generate("ocean", "medium", "standard", 42, [], {})
        assert puzzle is None
