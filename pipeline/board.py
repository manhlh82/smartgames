"""Crossword board representation with placement and scoring logic."""

from dataclasses import dataclass, field

EMPTY = " "
BLACK = "#"


@dataclass
class PlacementCandidate:
    row: int
    col: int
    direction: str  # "across" or "down"
    intersection_score: float


class Board:
    def __init__(self, rows: int, cols: int):
        self.rows = rows
        self.cols = cols
        self.cells: list[list[str]] = [[EMPTY] * cols for _ in range(rows)]
        self.placed: list[dict] = []  # list of PlacedEntry dicts (without number)

    # ------------------------------------------------------------------
    # Placement helpers
    # ------------------------------------------------------------------

    def _cell(self, row: int, col: int) -> str:
        if 0 <= row < self.rows and 0 <= col < self.cols:
            return self.cells[row][col]
        return BLACK  # treat out-of-bounds as blocker

    def can_place(self, word: str, row: int, col: int, direction: str) -> bool:
        """Return True if word can be placed without violating crossword rules.

        Rules checked:
          1. Bounds: entire word fits on board.
          2. Cell conflicts: each cell is EMPTY or already contains the matching letter.
          3. No adjacency at start/end: cell before start and cell after end must be EMPTY
             or out-of-bounds (no word can run into another word end-to-end).
          4. Perpendicular adjacency: cells perpendicular to the word body are allowed only
             if they are already occupied (i.e., they are crossing letters). Unoccupied
             perpendicular neighbours are fine; occupied neighbours that do NOT match the
             current word's letter would have been caught by rule 2.
          5. A placement that overlaps exactly with an already-placed word in the same
             direction is rejected (duplicate word or complete overlap).
        """
        n = len(word)
        dr, dc = (0, 1) if direction == "across" else (1, 0)
        # perpendicular deltas
        pr, pc = (1, 0) if direction == "across" else (0, 1)

        # 1. Bounds check
        end_r = row + dr * (n - 1)
        end_c = col + dc * (n - 1)
        if not (0 <= end_r < self.rows and 0 <= end_c < self.cols):
            return False

        # 3. No word immediately before start
        before_r = row - dr
        before_c = col - dc
        if 0 <= before_r < self.rows and 0 <= before_c < self.cols:
            if self.cells[before_r][before_c] != EMPTY:
                return False

        # 3. No word immediately after end
        after_r = row + dr * n
        after_c = col + dc * n
        if 0 <= after_r < self.rows and 0 <= after_c < self.cols:
            if self.cells[after_r][after_c] != EMPTY:
                return False

        matching_cells = 0  # cells where letters already match (intersections)

        for i, letter in enumerate(word):
            r = row + dr * i
            c = col + dc * i
            current = self.cells[r][c]

            # 2. Cell conflict
            if current != EMPTY and current != letter:
                return False

            if current == letter:
                matching_cells += 1
                # This is a crossing — verify it actually belongs to a word in
                # the perpendicular direction (not just a stray letter from a
                # parallel word).
                # For simplicity we allow crossing if there IS an existing placed
                # word that covers this cell in the opposite direction.
                opp_dir = "down" if direction == "across" else "across"
                if not self._cell_covered_by_direction(r, c, opp_dir):
                    # Letter matches but comes from a parallel word — reject.
                    return False
            else:
                # Cell is EMPTY. Check perpendicular neighbours are not occupied
                # (which would create an unintended merge with a parallel word).
                left_r, left_c = r - pr, c - pc
                right_r, right_c = r + pr, c + pc
                if self._cell(left_r, left_c) != EMPTY:
                    return False
                if self._cell(right_r, right_c) != EMPTY:
                    return False

        # Require at least one intersection when board is non-empty (except first word)
        if self.placed and matching_cells == 0:
            return False

        # 5. Reject if word is a full duplicate placement
        if matching_cells == n:
            return False

        return True

    def _cell_covered_by_direction(self, row: int, col: int, direction: str) -> bool:
        """Return True if any placed entry covers (row, col) in the given direction."""
        dr, dc = (0, 1) if direction == "across" else (1, 0)
        for entry in self.placed:
            if entry["direction"] != direction:
                continue
            er, ec = entry["row"], entry["col"]
            length = entry["length"]
            for i in range(length):
                if er + dr * i == row and ec + dc * i == col:
                    return True
        return False

    # ------------------------------------------------------------------
    # Place / remove
    # ------------------------------------------------------------------

    def place(
        self,
        word: str,
        row: int,
        col: int,
        direction: str,
        clue: str = "",
        soft_hints: dict = None,
        theme: str = "",
        difficulty: str = "",
    ) -> dict:
        """Place word on board and return a PlacedEntry dict (number = 0, assigned later)."""
        dr, dc = (0, 1) if direction == "across" else (1, 0)
        for i, letter in enumerate(word):
            self.cells[row + dr * i][col + dc * i] = letter

        entry = {
            "number": 0,
            "answer": word,
            "direction": direction,
            "row": row,
            "col": col,
            "length": len(word),
            "clue": clue,
            "softHints": soft_hints or {},
            "theme": theme,
            "difficulty": difficulty,
        }
        self.placed.append(entry)
        return entry

    def remove_placed(self, placed_entry: dict) -> None:
        """Remove a placed word from the board, restoring cells if not shared."""
        if placed_entry not in self.placed:
            return
        self.placed.remove(placed_entry)

        dr, dc = (0, 1) if placed_entry["direction"] == "across" else (1, 0)
        word = placed_entry["answer"]
        row, col = placed_entry["row"], placed_entry["col"]

        for i in range(len(word)):
            r, c = row + dr * i, col + dc * i
            # Only clear cell if no remaining placed entry covers it
            if not any(self._entry_covers(e, r, c) for e in self.placed):
                self.cells[r][c] = EMPTY

    def _entry_covers(self, entry: dict, row: int, col: int) -> bool:
        dr, dc = (0, 1) if entry["direction"] == "across" else (1, 0)
        for i in range(entry["length"]):
            if entry["row"] + dr * i == row and entry["col"] + dc * i == col:
                return True
        return False

    # ------------------------------------------------------------------
    # Candidate finding
    # ------------------------------------------------------------------

    def get_intersection_candidates(
        self, word: str, direction: str
    ) -> list[PlacementCandidate]:
        """Find all valid positions where word can cross an existing placed word.

        Score = position_score - crowding_penalty, favouring placements away from
        parallel words (to keep the board open for future placements).
        """
        candidates: list[PlacementCandidate] = []
        opp_dir = "down" if direction == "across" else "across"
        seen: set[tuple[int, int]] = set()  # deduplicate (start_r, start_c) per direction

        for existing in self.placed:
            if existing["direction"] != opp_dir:
                continue

            ex_word = existing["answer"]
            ex_row, ex_col = existing["row"], existing["col"]
            ex_dr, ex_dc = (0, 1) if opp_dir == "across" else (1, 0)

            # Try crossing each letter of `word` with each letter of `existing`
            for i, wl in enumerate(word):
                for j, el in enumerate(ex_word):
                    if wl != el:
                        continue
                    # Position of the crossing cell in existing
                    cross_r = ex_row + ex_dr * j
                    cross_c = ex_col + ex_dc * j

                    # Start of new word placement
                    dr, dc = (0, 1) if direction == "across" else (1, 0)
                    start_r = cross_r - dr * i
                    start_c = cross_c - dc * i

                    key = (start_r, start_c)
                    if key in seen:
                        continue

                    if self.can_place(word, start_r, start_c, direction):
                        seen.add(key)
                        # Base score: crossing near middle of existing word is better
                        pos_score = 1.0 - abs((j / max(len(ex_word) - 1, 1)) - 0.5) * 2
                        # Crowding penalty: count occupied parallel-direction cells
                        # adjacent to our new word body
                        crowding = self._count_parallel_neighbours(
                            word, start_r, start_c, direction
                        )
                        score = max(0.01, pos_score - 0.15 * crowding)
                        candidates.append(
                            PlacementCandidate(
                                row=start_r,
                                col=start_c,
                                direction=direction,
                                intersection_score=score,
                            )
                        )

        return candidates

    def _count_parallel_neighbours(
        self, word: str, row: int, col: int, direction: str
    ) -> int:
        """Count cells adjacent perpendicular to the word that are already occupied.

        Higher values mean the word is being squeezed between existing words.
        Only counts non-crossing cells (empty cells in the word body).
        """
        dr, dc = (0, 1) if direction == "across" else (1, 0)
        pr, pc = (1, 0) if direction == "across" else (0, 1)
        count = 0
        for i in range(len(word)):
            r, c = row + dr * i, col + dc * i
            if self.cells[r][c] != EMPTY:
                continue  # skip crossing cells
            if self._cell(r - pr, c - pc) != EMPTY:
                count += 1
            if self._cell(r + pr, c + pc) != EMPTY:
                count += 1
        return count

    # ------------------------------------------------------------------
    # Scoring
    # ------------------------------------------------------------------

    def score(self) -> float:
        """Score the current board state (0.0 – 1.0)."""
        if not self.placed:
            return 0.0

        target = 20  # normalisation denominator
        density = len(self.placed) / target

        # Connectivity: average intersections per word
        intersection_cells = self.count_intersections()
        connectivity = intersection_cells / max(len(self.placed), 1)

        # Fill ratio
        non_empty = sum(1 for r in self.cells for c in r if c != EMPTY)
        fill_ratio = non_empty / (self.rows * self.cols)

        word_count_ratio = len(self.placed) / 20

        return (
            0.30 * min(density, 1.0)
            + 0.25 * min(connectivity, 1.0)
            + 0.20 * min(fill_ratio, 1.0)
            + 0.25 * min(word_count_ratio, 1.0)
        )

    # ------------------------------------------------------------------
    # Numbering & grid export
    # ------------------------------------------------------------------

    def assign_numbers(self) -> dict:
        """Assign sequential numbers to word-start cells (left-to-right, top-to-bottom).

        Returns a mapping {(row, col): number}.
        Updates 'number' field in each placed entry.
        """
        # Collect cells that start an across or down word
        start_cells: set[tuple[int, int]] = set()
        for entry in self.placed:
            start_cells.add((entry["row"], entry["col"]))

        # Sort by reading order
        sorted_starts = sorted(start_cells, key=lambda rc: (rc[0], rc[1]))
        number_map: dict[tuple[int, int], int] = {}
        for idx, cell in enumerate(sorted_starts, start=1):
            number_map[cell] = idx

        # Update placed entries
        for entry in self.placed:
            entry["number"] = number_map.get((entry["row"], entry["col"]), 0)

        return number_map

    def to_solution_grid(self) -> list[list[str]]:
        """Return grid with letters; empty cells as empty string."""
        return [
            [c if c != EMPTY else "" for c in row]
            for row in self.cells
        ]

    def to_player_grid(self) -> list[list[str]]:
        """Return grid with empty strings everywhere (player fills in)."""
        return [
            ["" if c != EMPTY else None for c in row]
            for row in self.cells
        ]

    def count_intersections(self) -> int:
        """Count cells shared by 2+ words (intersection cells)."""
        cell_counts: dict[tuple[int, int], int] = {}
        for entry in self.placed:
            dr, dc = (0, 1) if entry["direction"] == "across" else (1, 0)
            for i in range(entry["length"]):
                key = (entry["row"] + dr * i, entry["col"] + dc * i)
                cell_counts[key] = cell_counts.get(key, 0) + 1
        return sum(1 for v in cell_counts.values() if v >= 2)
