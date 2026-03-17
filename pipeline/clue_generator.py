"""
Definition-based clue generation using Kaikki/Wiktionary dictionary data.

Priority order:
1. clue-overrides.json (manual)
2. Kaikki dictionary lookup → clean gloss → validate
3. Mark word as needs_review (do NOT use generic fallback as final clue)
"""

import re
from pipeline.models import ClueEntry

# Prepositions/articles that shouldn't end a truncated clue
_TRAILING_STOP_WORDS = {'a', 'an', 'the', 'of', 'for', 'to', 'in', 'on', 'at', 'by', 'and', 'or'}

# Generic phrases that indicate a low-quality clue
_GENERIC_PHRASES = {
    "a type of", "a kind of", "any of", "one of", "the act of",
    "relating to", "of or relating to", "pertaining to",
}


def clean_gloss(raw_gloss: str, answer: str) -> str | None:
    """Clean a Wiktionary gloss into a crossword-friendly clue.

    Returns cleaned string (≤10 words) or None if:
    - Clue contains the answer word
    - Result is too short (< 2 words)
    - Clue is still too generic after cleaning
    """
    text = raw_gloss

    # Strip wiki markup: [[link|text]] -> text, [[link]] -> link
    text = re.sub(r'\[\[(?:[^\]|]+\|)?([^\]]+)\]\]', r'\1', text)
    # Strip template refs {{...}}
    text = re.sub(r'\{\{[^}]+\}\}', '', text)
    # Strip short parentheticals (up to 40 chars)
    text = re.sub(r'\([^)]{0,40}\)', '', text)
    # Strip HTML entities and tags
    text = re.sub(r'&[a-z]+;', '', text)
    text = re.sub(r'<[^>]+>', '', text)
    # Collapse whitespace
    text = re.sub(r'\s+', ' ', text).strip()

    # Remove trailing period, capitalize first letter
    text = text.rstrip('.').strip()
    if text:
        text = text[0].upper() + text[1:]

    # Truncate to ≤10 words (avoid ending on a preposition/article)
    words = text.split()
    if len(words) > 10:
        text = ' '.join(words[:8])
        last = words[7].lower()
        if last in _TRAILING_STOP_WORDS:
            text = ' '.join(words[:7])

    if not text or len(text.split()) < 2:
        return None

    # Reject if answer word appears in clue
    answer_lower = answer.lower()
    clue_lower = text.lower()
    clue_words = {w.strip('.,;:') for w in clue_lower.split()}
    if answer_lower in clue_words:
        return None
    # Also reject partial matches for short words (≤5 chars)
    if len(answer) <= 5 and answer_lower in clue_lower:
        return None

    # Reject if too generic (short phrase starting with known generic prefix)
    text_lower_stripped = text.lower()
    if any(text_lower_stripped.startswith(p) for p in _GENERIC_PHRASES) and len(text.split()) <= 5:
        return None

    return text


def generate_clue_from_dict(word: str, glosses: list[str]) -> tuple[str | None, str]:
    """Try each gloss in order, return (cleaned_clue, source_gloss) or (None, '').

    Returns the first valid cleaned gloss.
    """
    for gloss in glosses:
        cleaned = clean_gloss(gloss, word)
        if cleaned:
            return cleaned, gloss
    return None, ""


def make_clue_entry(
    word: str,
    theme: str,
    difficulty: str,
    lookup: dict,
    word_source: str = "",
    override: dict | None = None,
) -> dict:
    """Build a ClueEntry dict for a word.

    Priority: override → dictionary lookup → needs_review
    Returns ClueEntry.to_dict()
    """
    soft_hints = {"startsWith": word[0], "length": len(word), "category": theme}

    # 1. Manual override
    if override:
        return ClueEntry(
            word=word,
            primaryClue=override.get("primaryClue", ""),
            alternateClues=override.get("alternateClues", []),
            softHints=soft_hints,
            difficulty=difficulty,
            source="override",
            reviewFlags=[],
            approved=True,
            clueSource="override",
            sourceDefinition="",
            clueGenerationMethod="manual_override",
            licenseNotes="manual",
            needsReview=False,
        ).to_dict()

    # 2. Dictionary lookup
    glosses = lookup.get(word, [])
    if glosses:
        clue, raw_gloss = generate_clue_from_dict(word, glosses)
        if clue:
            # Build alternate clues from remaining glosses
            alternate_clues = [
                clean_gloss(g, word)
                for g in glosses[1:]
                if clean_gloss(g, word)
            ]
            return ClueEntry(
                word=word,
                primaryClue=clue,
                alternateClues=alternate_clues,
                softHints=soft_hints,
                difficulty=difficulty,
                source="kaikki",
                reviewFlags=[],
                approved=True,
                clueSource="kaikki",
                sourceDefinition=raw_gloss,
                clueGenerationMethod="dictionary_gloss",
                licenseNotes="CC BY-SA 4.0 (Wiktionary via Kaikki.org)",
                needsReview=False,
            ).to_dict()

    # 3. No specific clue found → needs_review
    return ClueEntry(
        word=word,
        primaryClue="",
        alternateClues=[],
        softHints=soft_hints,
        difficulty=difficulty,
        source="needs_review",
        reviewFlags=["no_definition_found"],
        approved=False,
        clueSource="none",
        sourceDefinition="",
        clueGenerationMethod="excluded",
        licenseNotes="",
        needsReview=True,
    ).to_dict()
