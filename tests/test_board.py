"""Tests for pipeline.board.Board — placement, numbering, grid export."""

import pytest
from pipeline.board import Board, EMPTY


class TestBoardPlacement:
    def test_place_across_fills_cells(self):
        board = Board(7, 7)
        board.place("CAT", 0, 0, "across")
        assert board.cells[0][0] == "C"
        assert board.cells[0][1] == "A"
        assert board.cells[0][2] == "T"

    def test_can_place_conflict_returns_false(self):
        # CAT at (0,0) across occupies (0,0)-(0,2); DOG across at same row conflicts
        board = Board(7, 7)
        board.place("CAT", 0, 0, "across")
        assert board.can_place("DOG", 0, 0, "across") is False

    def test_can_place_on_empty_board(self):
        board = Board(7, 7)
        assert board.can_place("DOG", 2, 0, "across") is True

    def test_can_place_out_of_bounds_returns_false(self):
        board = Board(7, 7)
        # "TOOLONGWORD" is 11 chars; starting at col 0 on a 7-wide board overflows
        assert board.can_place("TOOLONGWORD", 0, 0, "across") is False

    def test_crossing_shared_letter_valid(self):
        # Place CAT across at row 0, col 0 → A at (0,1)
        # Place ARC down at row 0, col 1 → A at (0,1), crossing CAT at A
        board = Board(7, 7)
        board.place("CAT", 0, 0, "across")
        # ARC down starting at (0,1): A at (0,1) already matches
        assert board.can_place("ARC", 0, 1, "down") is True

    def test_place_crossing_word(self):
        board = Board(7, 7)
        board.place("CAT", 0, 0, "across")
        entry = board.place("ARC", 0, 1, "down")
        assert entry["answer"] == "ARC"
        assert len(board.placed) == 2

    def test_can_place_respects_end_adjacency(self):
        # CAT ends at (0,2); DOG immediately after would start at (0,3) — but
        # there must be no occupied cell right before start of new word.
        # Place CAT; then try to place DOG starting at (0,3) — CAT's last letter
        # is at (0,2), so the cell before DOG's start is occupied → rejected.
        board = Board(7, 7)
        board.place("CAT", 0, 0, "across")
        assert board.can_place("DOG", 0, 3, "across") is False


class TestBoardNumbers:
    def test_assign_numbers_returns_dict_with_int_values(self):
        board = Board(7, 7)
        board.place("CAT", 0, 0, "across")
        board.place("ARC", 0, 1, "down")
        number_map = board.assign_numbers()
        assert isinstance(number_map, dict)
        for v in number_map.values():
            assert isinstance(v, int)

    def test_assign_numbers_updates_placed_entries(self):
        board = Board(7, 7)
        board.place("CAT", 0, 0, "across")
        board.place("ARC", 0, 1, "down")
        board.assign_numbers()
        for entry in board.placed:
            assert entry["number"] > 0


class TestBoardExport:
    def test_solution_grid_returns_nested_list(self):
        board = Board(5, 5)
        board.place("CAT", 0, 0, "across")
        grid = board.to_solution_grid()
        assert isinstance(grid, list)
        assert isinstance(grid[0], list)
        assert grid[0][0] == "C"

    def test_solution_grid_empty_cells_are_empty_string(self):
        board = Board(5, 5)
        board.place("CAT", 0, 0, "across")
        grid = board.to_solution_grid()
        # Cell (0,3) was never filled — should be ""
        assert grid[0][3] == ""

    def test_count_intersections_two_crossing_words(self):
        board = Board(7, 7)
        board.place("CAT", 0, 0, "across")
        board.place("ARC", 0, 1, "down")
        assert board.count_intersections() >= 1

    def test_count_intersections_empty_board(self):
        board = Board(7, 7)
        assert board.count_intersections() == 0
