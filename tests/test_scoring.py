"""Tests for pipeline.scoring — compute_crossword_fit, compute_theme_fit, assign_difficulty."""

from pipeline.scoring import compute_crossword_fit, compute_theme_fit, assign_difficulty


class TestComputeCrosswordFit:
    def test_score_in_range(self):
        score = compute_crossword_fit("CAT")
        assert 0.0 <= score <= 1.0

    def test_all_vowels_lower_than_balanced(self):
        # "AEIOU" has 100% vowel ratio — penalised; "WHALE" has good balance
        assert compute_crossword_fit("AEIOU") < compute_crossword_fit("WHALE")

    def test_empty_string_returns_zero(self):
        assert compute_crossword_fit("") == 0.0

    def test_long_word_scores_lower_than_medium(self):
        # 12-char word falls outside peak range [4, 8]
        assert compute_crossword_fit("ABCDEFGHIJKL") < compute_crossword_fit("OCEAN")

    def test_diversity_matters(self):
        # "AAAA" has no letter diversity; "WORD" has full diversity
        assert compute_crossword_fit("AAAA") < compute_crossword_fit("WORD")


class TestComputeThemeFit:
    def test_topic_list_returns_one(self):
        assert compute_theme_fit("X", "topic_list") == 1.0

    def test_general_returns_half(self):
        assert compute_theme_fit("X", "general") == 0.5

    def test_frequency_returns_low(self):
        assert compute_theme_fit("X", "frequency") == 0.3

    def test_unknown_source_defaults_to_half(self):
        assert compute_theme_fit("X", "unknown_source") == 0.5


class TestAssignDifficulty:
    def test_high_scores_return_easy(self):
        # popularity >= 0.65 AND crossword_fit >= 0.60
        assert assign_difficulty(0.7, 0.7) == "easy"

    def test_low_popularity_returns_hard(self):
        # popularity < 0.40
        assert assign_difficulty(0.3, 0.7) == "hard"

    def test_low_fit_returns_hard(self):
        # crossword_fit < 0.45
        assert assign_difficulty(0.7, 0.4) == "hard"

    def test_middle_scores_return_medium(self):
        # neither easy nor hard thresholds met
        assert assign_difficulty(0.55, 0.55) == "medium"

    def test_boundary_easy_popularity(self):
        # exactly at boundary: 0.65 pop and 0.60 fit → easy
        assert assign_difficulty(0.65, 0.60) == "easy"

    def test_just_below_easy_popularity(self):
        # 0.64 pop fails easy threshold but doesn't hit hard
        result = assign_difficulty(0.64, 0.65)
        assert result in ("medium", "hard")
