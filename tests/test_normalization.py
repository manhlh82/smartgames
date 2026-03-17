"""Tests for pipeline.normalization — normalize_word and is_valid_word."""

import pytest
from pipeline.normalization import normalize_word, is_valid_word


class TestNormalizeWord:
    def test_accented_char_returns_none(self):
        assert normalize_word("café") is None

    def test_apostrophe_returns_none(self):
        assert normalize_word("don't") is None

    def test_uppercase_input_preserved(self):
        assert normalize_word("WHALE") == "WHALE"

    def test_lowercase_uppercased(self):
        assert normalize_word("whale") == "WHALE"

    def test_too_short_returns_none(self):
        # length 2 is below minimum of 3
        assert normalize_word("hi") is None

    def test_strips_whitespace(self):
        assert normalize_word("  cat  ") == "CAT"

    def test_exceeds_max_length_returns_none(self):
        # >12 chars
        assert normalize_word("SUPERLONGWORDTHATEXCEEDSMAXLENGTH") is None

    def test_empty_string_returns_none(self):
        assert normalize_word("") is None

    def test_multi_word_returns_none(self):
        assert normalize_word("blue whale") is None

    def test_exactly_three_chars(self):
        assert normalize_word("cat") == "CAT"

    def test_exactly_twelve_chars(self):
        word = "A" * 12
        assert normalize_word(word) == word

    def test_thirteen_chars_returns_none(self):
        assert normalize_word("A" * 13) is None


class TestIsValidWord:
    def test_valid_word_passes(self):
        valid, reason = is_valid_word("DOLPHIN", set(), set())
        assert valid is True
        assert reason is None

    def test_denylist_word_rejected(self):
        valid, reason = is_valid_word("BADWORD", {"badword"}, set())
        assert valid is False
        assert reason == "denylist"

    def test_allowlist_bypasses_denylist(self):
        # Word on both denylist and allowlist — allowlist wins
        valid, reason = is_valid_word("CORAL", {"coral"}, {"coral"})
        assert valid is True

    def test_too_short_rejected(self):
        valid, reason = is_valid_word("AB", set(), set())
        assert valid is False
        assert "too_short" in reason

    def test_too_long_rejected(self):
        valid, reason = is_valid_word("A" * 13, set(), set())
        assert valid is False
        assert "too_long" in reason

    def test_invalid_chars_rejected(self):
        valid, reason = is_valid_word("CAF\xc9", set(), set())
        assert valid is False
        assert reason == "invalid_chars"
