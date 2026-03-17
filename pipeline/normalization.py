"""Word normalization and validation for the crossword pipeline."""

import re

_ALLOWED_RE = re.compile(r"^[A-Z]+$")


def normalize_word(word: str) -> str | None:
    """Normalize a raw word to uppercase crossword-safe form.

    Returns None if the word is invalid (non-alpha, too short/long, has spaces).
    """
    if not word:
        return None

    # Reject multi-word phrases immediately
    if " " in word.strip():
        return None

    normalized = word.strip().upper()

    # Must be purely A-Z after uppercasing
    if not _ALLOWED_RE.match(normalized):
        return None

    length = len(normalized)
    if length < 3 or length > 12:
        return None

    return normalized


def is_valid_word(
    word: str,
    denylist: set,
    allowlist: set,
    min_len: int = 3,
    max_len: int = 12,
) -> tuple[bool, str | None]:
    """Validate a normalized (uppercase) word against rules.

    Args:
        word: Already-normalized uppercase word.
        denylist: Set of banned lowercase words.
        allowlist: Set of explicitly allowed lowercase words (bypasses denylist).
        min_len: Minimum allowed length.
        max_len: Maximum allowed length.

    Returns:
        (True, None) if valid; (False, reason_string) if invalid.
    """
    lower = word.lower()

    # Allowlist bypasses all checks except character validity
    if lower in allowlist:
        if _ALLOWED_RE.match(word):
            return True, None
        return False, "invalid_chars"

    # Length check
    if len(word) < min_len:
        return False, f"too_short (min={min_len})"
    if len(word) > max_len:
        return False, f"too_long (max={max_len})"

    # Character check
    if not _ALLOWED_RE.match(word):
        return False, "invalid_chars"

    # Denylist check
    if lower in denylist:
        return False, "denylist"

    return True, None
