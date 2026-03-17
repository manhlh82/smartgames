"""Crossword puzzle generator using greedy placement with restarts."""

import random
import time
from typing import Optional

from pipeline.board import Board
from pipeline.models import PuzzleOutput

BOARD_SIZE_CONFIG = {
    "mini":     {"rows": 7,  "cols": 7,  "target_words": 7,  "min_words": 4},
    "standard": {"rows": 9,  "cols": 9,  "target_words": 12, "min_words": 7},
    "extended": {"rows": 11, "cols": 11, "target_words": 18, "min_words": 10},
}

# Minimum board score to accept without exhausting all restarts
_ACCEPT_SCORE_THRESHOLD = 0.35


class CrosswordGenerator:
    """Generate a crossword puzzle from a word bank and clue map."""

    def generate(
        self,
        theme: str,
        difficulty: str,
        board_size: str,
        seed: int,
        word_bank: list[dict],
        clue_map: dict[str, dict],
        max_restarts: int = 5,
        timeout_seconds: float = 10.0,
    ) -> Optional[dict]:
        """Generate a crossword puzzle dict (PuzzleOutput) or None if not enough words.

        Algorithm:
          1. Filter word_bank to allowed words (difficulty-matched with fallback).
          2. Sort by composite score descending.
          3. For each restart attempt:
             a. Seed RNG, shuffle candidate pool.
             b. Build fresh Board.
             c. Place anchor word horizontally in centre row.
             d. Greedily try every remaining word in both directions via intersections.
             e. Evaluate; keep best board found.
          4. Return best PuzzleOutput dict, or None if min_words never reached.
        """
        cfg = BOARD_SIZE_CONFIG.get(board_size)
        if cfg is None:
            raise ValueError(
                f"Unknown board_size '{board_size}'. Choose from: {list(BOARD_SIZE_CONFIG)}"
            )

        rows, cols = cfg["rows"], cfg["cols"]
        target_words = cfg["target_words"]
        min_words = cfg["min_words"]

        # --- 1. Filter and rank candidates ---
        candidates = self._filter_candidates(word_bank, difficulty)
        if not candidates:
            return None

        candidates.sort(key=lambda w: self._composite_score(w), reverse=True)
        # Use the full candidate pool so restarts have words to try
        pool = candidates

        start_time = time.monotonic()
        best_board: Optional[Board] = None
        best_score = -1.0

        for restart in range(max_restarts):
            if time.monotonic() - start_time > timeout_seconds:
                break

            rng = random.Random(seed + restart)

            # Shuffle a large working set; sort longest-first to anchor well
            working = list(pool)
            rng.shuffle(working)
            working.sort(key=lambda w: len(w["word"]), reverse=True)

            board = Board(rows, cols)
            placed_words: set[str] = set()

            # --- c. Place anchor word horizontally in centre row ---
            # Prefer words that are 60-80% of board width to leave columns free
            # for down-word crossings. Fall back to longest that fits.
            ideal_max = max(3, int(cols * 0.80))
            ideal_min = max(3, int(cols * 0.40))
            anchor = next(
                (w for w in working if ideal_min <= len(w["word"]) <= ideal_max),
                next((w for w in working if len(w["word"]) <= cols), None),
            )
            if anchor is None:
                continue
            anchor_word = anchor["word"]
            center_row = rows // 2
            center_col = max(0, (cols - len(anchor_word)) // 2)

            clue_entry = clue_map.get(anchor_word, {})
            board.place(
                word=anchor_word,
                row=center_row,
                col=center_col,
                direction="across",
                clue=clue_entry.get("primaryClue", ""),
                soft_hints=clue_entry.get("softHints", {}),
                theme=theme,
                difficulty=anchor.get("difficulty", difficulty),
            )
            placed_words.add(anchor_word)

            # --- d. Greedy placement pass (up to target_words total) ---
            # Track direction counts to enforce balance: don't let one direction
            # dominate (which boxes in the board).  After every 2 placements in the
            # same direction, force the opposite direction for the next word.
            dir_counts = {"across": 1, "down": 0}  # anchor counts as across
            skipped_words = list(working[1:])  # words still to place
            max_passes = 3  # re-try skipped words this many times

            for _pass in range(max_passes):
                still_skipped = []
                for word_entry in skipped_words:
                    if len(placed_words) >= target_words:
                        break
                    if time.monotonic() - start_time > timeout_seconds:
                        break

                    word = word_entry["word"]
                    if word in placed_words:
                        continue

                    # Determine preferred direction based on balance
                    if dir_counts["down"] < dir_counts["across"]:
                        pref_dirs = ["down", "across"]
                    elif dir_counts["across"] < dir_counts["down"]:
                        pref_dirs = ["across", "down"]
                    else:
                        pref_dirs = ["down", "across"]  # default: down first

                    placed = False
                    for direction in pref_dirs:
                        cands = board.get_intersection_candidates(word, direction)
                        if cands:
                            best = max(cands, key=lambda c: c.intersection_score)
                            clue_entry = clue_map.get(word, {})
                            board.place(
                                word=word,
                                row=best.row,
                                col=best.col,
                                direction=best.direction,
                                clue=clue_entry.get("primaryClue", ""),
                                soft_hints=clue_entry.get("softHints", {}),
                                theme=theme,
                                difficulty=word_entry.get("difficulty", difficulty),
                            )
                            placed_words.add(word)
                            dir_counts[best.direction] += 1
                            placed = True
                            break

                    if not placed:
                        still_skipped.append(word_entry)

                skipped_words = still_skipped
                if not still_skipped:
                    break

            # --- e. Evaluate board ---
            if len(board.placed) >= min_words:
                sc = board.score()
                if sc > best_score:
                    best_score = sc
                    best_board = board
                if sc >= _ACCEPT_SCORE_THRESHOLD:
                    break

        if best_board is None or len(best_board.placed) < min_words:
            return None

        return self._build_puzzle_output(
            board=best_board,
            theme=theme,
            difficulty=difficulty,
            rows=rows,
            cols=cols,
            seed=seed,
            board_size=board_size,
        )

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _filter_candidates(self, word_bank: list[dict], difficulty: str) -> list[dict]:
        """Return allowed words matching difficulty; fall back to all allowed words."""
        allowed = [w for w in word_bank if w.get("allowInGame", True)]
        exact = [w for w in allowed if w.get("difficulty") == difficulty]
        return exact if len(exact) >= 5 else allowed

    def _composite_score(self, word_entry: dict) -> float:
        pop = word_entry.get("popularityScore", 0.5)
        fit = word_entry.get("crosswordFitScore", 0.5)
        theme_fit = word_entry.get("themeFitScore", 0.5)
        return 0.4 * pop + 0.4 * fit + 0.2 * theme_fit

    def _try_place_word(
        self,
        board: Board,
        word_entry: dict,
        direction: str,
        clue_map: dict[str, dict],
        theme: str,
    ) -> bool:
        """Attempt to place word via intersection. Returns True if placed."""
        word = word_entry["word"]
        candidates = board.get_intersection_candidates(word, direction)
        if not candidates:
            return False

        # Pick candidate with highest intersection score
        candidates.sort(key=lambda c: c.intersection_score, reverse=True)
        best = candidates[0]

        clue_entry = clue_map.get(word, {})
        board.place(
            word=word,
            row=best.row,
            col=best.col,
            direction=best.direction,
            clue=clue_entry.get("primaryClue", ""),
            soft_hints=clue_entry.get("softHints", {}),
            theme=theme,
            difficulty=word_entry.get("difficulty", ""),
        )
        return True

    def _build_puzzle_output(
        self,
        board: Board,
        theme: str,
        difficulty: str,
        rows: int,
        cols: int,
        seed: int,
        board_size: str,
    ) -> dict:
        """Finalise numbers and build PuzzleOutput dict."""
        board.assign_numbers()

        entries = [dict(e) for e in board.placed]

        across_clues = sorted(
            [e for e in entries if e["direction"] == "across"],
            key=lambda e: e["number"],
        )
        down_clues = sorted(
            [e for e in entries if e["direction"] == "down"],
            key=lambda e: e["number"],
        )

        puzzle_id = f"{theme}-{difficulty}-{rows}x{cols}-{seed:04d}"

        puzzle = PuzzleOutput(
            puzzleId=puzzle_id,
            seed=seed,
            theme=theme,
            difficulty=difficulty,
            rows=rows,
            cols=cols,
            solutionGrid=board.to_solution_grid(),
            playerGrid=board.to_player_grid(),
            entries=entries,
            clueGroups={
                "across": [self._clue_summary(e) for e in across_clues],
                "down":   [self._clue_summary(e) for e in down_clues],
            },
            uiMetadata={
                "boardSize": board_size,
                "theme": theme,
                "difficulty": difficulty,
            },
            stats={
                "wordCount": len(entries),
                "intersections": board.count_intersections(),
                "boardScore": round(board.score(), 4),
            },
        )
        return puzzle.to_dict()

    def _clue_summary(self, entry: dict) -> dict:
        return {
            "number": entry["number"],
            "clue": entry["clue"],
            "answer": entry["answer"],
            "length": entry["length"],
        }
