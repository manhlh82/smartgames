"""Word scoring functions for crossword suitability and difficulty assignment."""

_VOWELS = set("AEIOU")


def compute_popularity(word: str, freq_map: dict[str, float]) -> float:
    """Return normalized popularity score 0.0-1.0.

    Uses freq_map (word -> 0.0-1.0) if the word is present, else 0.5.
    """
    return freq_map.get(word.upper(), freq_map.get(word.lower(), 0.5))


def compute_crossword_fit(word: str) -> float:
    """Score how well a word fits in a crossword grid (0.0-1.0).

    Components:
      - diversity:      unique_letters / length  (more variety = better crossings)
      - vowel_balance:  penalize if vowel ratio < 0.2 or > 0.7
      - length_fit:     peak at 4-8 letters, linear ramps outside that range

    Final: 0.4*diversity + 0.3*vowel_balance + 0.3*length_fit
    """
    upper = word.upper()
    n = len(upper)
    if n == 0:
        return 0.0

    # Diversity: unique letters
    diversity = len(set(upper)) / n

    # Vowel balance
    vowel_count = sum(1 for c in upper if c in _VOWELS)
    vowel_ratio = vowel_count / n
    if vowel_ratio < 0.2 or vowel_ratio > 0.7:
        vowel_balance = 0.0
    else:
        # Map 0.2-0.7 to a score: peak at ~0.35-0.45
        center = 0.40
        deviation = abs(vowel_ratio - center) / 0.30  # 0.0 at center, 1.0 at edges
        vowel_balance = max(0.0, 1.0 - deviation)

    # Length fit: peak [4, 8], ramp down outside
    if 4 <= n <= 8:
        length_fit = 1.0
    elif n < 4:
        length_fit = (n - 3) / 1.0  # 3->0.0, 4->1.0 (but 3 already < 4)
        length_fit = max(0.0, (n - 2) / 2.0)
    else:
        # n > 8: decay toward 12
        length_fit = max(0.0, 1.0 - (n - 8) / 4.0)

    return 0.4 * diversity + 0.3 * vowel_balance + 0.3 * length_fit


def compute_theme_fit(word: str, source_type: str) -> float:
    """Score how thematically relevant a word is based on its source type.

    - "topic_list"  -> 1.0  (curated topic word list)
    - "general"     -> 0.5  (general dictionary)
    - "frequency"   -> 0.3  (frequency-ranked corpus, weakest theme signal)
    """
    mapping = {
        "topic_list": 1.0,
        "general": 0.5,
        "frequency": 0.3,
    }
    return mapping.get(source_type, 0.5)


def assign_difficulty(popularity: float, crossword_fit: float) -> str:
    """Assign easy / medium / hard based on popularity and crossword fit scores.

    Rules:
      easy:   popularity >= 0.65 AND crossword_fit >= 0.60
      hard:   popularity <  0.40 OR  crossword_fit <  0.45
      medium: everything else
    """
    if popularity >= 0.65 and crossword_fit >= 0.60:
        return "easy"
    if popularity < 0.40 or crossword_fit < 0.45:
        return "hard"
    return "medium"
