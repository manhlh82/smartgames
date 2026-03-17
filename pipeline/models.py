"""Dataclasses for the crossword content pipeline. Pure stdlib, no pydantic."""

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class WordEntry:
    """A candidate word with scoring metadata."""

    word: str
    normalizedWord: str
    theme: str
    source: str
    sourceType: str  # "topic_list" | "general" | "frequency"
    difficulty: str  # "easy" | "medium" | "hard"
    popularityScore: float
    crosswordFitScore: float
    themeFitScore: float
    allowInGame: bool
    bannedReason: Optional[str]
    tags: list
    clueCandidates: list
    softHints: dict
    notes: str

    def to_dict(self) -> dict:
        return {
            "word": self.word,
            "normalizedWord": self.normalizedWord,
            "theme": self.theme,
            "source": self.source,
            "sourceType": self.sourceType,
            "difficulty": self.difficulty,
            "popularityScore": self.popularityScore,
            "crosswordFitScore": self.crosswordFitScore,
            "themeFitScore": self.themeFitScore,
            "allowInGame": self.allowInGame,
            "bannedReason": self.bannedReason,
            "tags": self.tags,
            "clueCandidates": self.clueCandidates,
            "softHints": self.softHints,
            "notes": self.notes,
        }


@dataclass
class ClueEntry:
    """Clue data for a single word."""

    word: str
    primaryClue: str
    alternateClues: list
    softHints: dict  # letter-position hints keyed by index
    difficulty: str
    source: str  # "generated" | "manual" | "override"
    reviewFlags: list
    approved: bool

    def to_dict(self) -> dict:
        return {
            "word": self.word,
            "primaryClue": self.primaryClue,
            "alternateClues": self.alternateClues,
            "softHints": self.softHints,
            "difficulty": self.difficulty,
            "source": self.source,
            "reviewFlags": self.reviewFlags,
            "approved": self.approved,
        }


@dataclass
class PlacedEntry:
    """A word placed on the crossword grid."""

    number: int
    answer: str
    direction: str  # "across" | "down"
    row: int
    col: int
    length: int
    clue: str
    softHints: dict
    theme: str
    difficulty: str

    def to_dict(self) -> dict:
        return {
            "number": self.number,
            "answer": self.answer,
            "direction": self.direction,
            "row": self.row,
            "col": self.col,
            "length": self.length,
            "clue": self.clue,
            "softHints": self.softHints,
            "theme": self.theme,
            "difficulty": self.difficulty,
        }


@dataclass
class PuzzleOutput:
    """A complete generated puzzle ready for export."""

    puzzleId: str
    seed: int
    theme: str
    difficulty: str
    rows: int
    cols: int
    solutionGrid: list  # list of list of str
    playerGrid: list    # list of list of str (blanks for letters)
    entries: list       # list of PlacedEntry dicts
    clueGroups: dict    # {"across": [...], "down": [...]}
    uiMetadata: dict
    stats: dict

    def to_dict(self) -> dict:
        return {
            "puzzleId": self.puzzleId,
            "seed": self.seed,
            "theme": self.theme,
            "difficulty": self.difficulty,
            "rows": self.rows,
            "cols": self.cols,
            "solutionGrid": self.solutionGrid,
            "playerGrid": self.playerGrid,
            "entries": self.entries,
            "clueGroups": self.clueGroups,
            "uiMetadata": self.uiMetadata,
            "stats": self.stats,
        }


@dataclass
class PackMeta:
    """Metadata for a puzzle pack (used in index)."""

    packId: str
    title: str
    theme: str
    difficulty: str
    boardSize: str   # "mini" | "standard" | "extended"
    puzzleCount: int
    resourceFile: str
    isUnlocked: bool
    createdAt: str   # ISO date string
    version: str

    def to_dict(self) -> dict:
        return {
            "packId": self.packId,
            "title": self.title,
            "theme": self.theme,
            "difficulty": self.difficulty,
            "boardSize": self.boardSize,
            "puzzleCount": self.puzzleCount,
            "resourceFile": self.resourceFile,
            "isUnlocked": self.isUnlocked,
            "createdAt": self.createdAt,
            "version": self.version,
        }


@dataclass
class Pack:
    """A full puzzle pack with all puzzles embedded."""

    packId: str
    title: str
    theme: str
    difficulty: str
    boardSize: str
    puzzles: list  # list of PuzzleOutput dicts

    def to_dict(self) -> dict:
        return {
            "packId": self.packId,
            "title": self.title,
            "theme": self.theme,
            "difficulty": self.difficulty,
            "boardSize": self.boardSize,
            "puzzles": self.puzzles,
        }


@dataclass
class PacksIndex:
    """Top-level index of all available packs."""

    version: str
    packs: list  # list of PackMeta dicts

    def to_dict(self) -> dict:
        return {
            "version": self.version,
            "packs": self.packs,
        }
