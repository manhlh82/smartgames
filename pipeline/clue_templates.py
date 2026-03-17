"""Template-based clue generation for all 12 crossword themes."""

from pipeline.models import ClueEntry

# Templates keyed by theme — list of generic clue strings (no {word} interpolation)
THEME_TEMPLATES: dict[str, list[str]] = {
    "animals": [
        "A type of animal",
        "Common household pet or wild creature",
        "Found in nature or a zoo",
        "Furry, feathered, or scaled creature",
        "Creature in the animal kingdom",
    ],
    "food": [
        "Something you eat",
        "Found in a kitchen or restaurant",
        "A tasty dish or ingredient",
        "Edible item",
        "Food item",
    ],
    "fruits": [
        "A sweet fruit",
        "Found in an orchard",
        "Grows on a tree or vine",
        "Healthy snack option",
        "Fruit variety",
    ],
    "ocean": [
        "Found in the sea",
        "Marine creature or feature",
        "Lives in the ocean",
        "Underwater dweller",
        "Ocean-related term",
    ],
    "space": [
        "Found in the cosmos",
        "Astronomical term",
        "Studied by NASA",
        "Celestial object or phenomenon",
        "Space exploration term",
    ],
    "nature": [
        "Found in nature",
        "Plant or natural feature",
        "Grows in the wild",
        "Part of the natural world",
        "Flora or natural element",
    ],
    "sports": [
        "A sport or athletic term",
        "Played in competition",
        "Athletic activity",
        "Sports-related word",
        "Game or sport",
    ],
    "music": [
        "Musical term",
        "Related to music",
        "Found in a song or concert",
        "Music vocabulary",
        "Instrument or musical concept",
    ],
    "travel": [
        "A way to travel",
        "Transportation method",
        "Used for getting around",
        "Travel-related term",
        "Vehicle or travel concept",
    ],
    "city": [
        "Found in a city",
        "Urban feature or place",
        "Part of city life",
        "City infrastructure term",
        "Metropolitan feature",
    ],
    "school": [
        "Found at school",
        "Education-related term",
        "Part of school life",
        "Academic term",
        "Classroom or school concept",
    ],
    "weather": [
        "A weather condition",
        "Meteorological term",
        "Related to the weather",
        "Climate or weather event",
        "What the forecast might show",
    ],
}

# Fallback for unknown themes
_DEFAULT_TEMPLATES = [
    "A common word",
    "Dictionary entry",
    "Word puzzle answer",
    "Part of everyday vocabulary",
    "Common English word",
]


def _pick_template(word: str, theme: str) -> str:
    """Select a template deterministically based on word hash."""
    templates = THEME_TEMPLATES.get(theme, _DEFAULT_TEMPLATES)
    idx = abs(hash(word)) % len(templates)
    return templates[idx]


def generate_clue(word_entry: dict, theme: str) -> dict:
    """Generate a ClueEntry dict for a word entry.

    Priority:
      1. clueCandidates if non-empty
      2. Template fallback from THEME_TEMPLATES

    Populates softHints with startsWith, length, category.
    Sets reviewFlags: 'short_clue' if clue < 3 words, 'fallback_only' if template used.
    """
    word = word_entry["word"]
    candidates: list[str] = word_entry.get("clueCandidates", [])
    review_flags: list[str] = []

    if candidates:
        primary_clue = candidates[0]
        alternate_clues = candidates[1:]
        source = "generated"
    else:
        primary_clue = _pick_template(word, theme)
        alternate_clues = []
        source = "generated"
        review_flags.append("fallback_only")

    # Flag short clues
    if len(primary_clue.split()) < 3:
        review_flags.append("short_clue")

    soft_hints: dict = {
        "startsWith": word[0],
        "length": len(word),
        "category": theme,
    }

    entry = ClueEntry(
        word=word,
        primaryClue=primary_clue,
        alternateClues=alternate_clues,
        softHints=soft_hints,
        difficulty=word_entry.get("difficulty", "medium"),
        source=source,
        reviewFlags=review_flags,
        approved=len(review_flags) == 0,
    )
    return entry.to_dict()
