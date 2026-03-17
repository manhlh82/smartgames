# Crossword Puzzle Pipeline Dictionary & Grid Fix Research

**Date:** 2026-03-18
**Focus:** Wordlist structure, Wiktionary JSON, gloss cleaning, SwiftUI black cell implementation

---

## TOPIC 1: imsky/wordlists GitHub Repository Structure

**Repo URL:** https://github.com/imsky/wordlists

**Directory Structure:**
- `nouns/` — 78 category files, each `category.txt` format
- `adjectives/`
- `verbs/`
- `names/` (includes `states/` subdirectory)
- `ipsum/`

**Category Files Mapping (nouns/ directory):**

| Theme | File Path |
|-------|-----------|
| Animals | `nouns/dogs.txt`, `nouns/cats.txt`, `nouns/birds.txt`, `nouns/fish.txt`, `nouns/snakes.txt`, `nouns/apex_predators.txt`, `nouns/monkeys.txt` |
| Food | `nouns/food.txt`, `nouns/fruit.txt`, `nouns/meat.txt`, `nouns/cheese.txt`, `nouns/seasonings.txt`, `nouns/condiments.txt`, `nouns/fast_food.txt` |
| Ocean/Sea | *(Not explicitly listed; may need custom aggregation)* |
| Space/Astronomy | `nouns/astronomy.txt` |
| Nature/Plants | `nouns/plants.txt` |
| Sports | `nouns/sports.txt` |
| Music | `nouns/music_instruments.txt`, `nouns/music_theory.txt`, `nouns/music_production.txt` |
| Travel/Transportation | `nouns/automobiles.txt`, `nouns/travel.txt` |
| City/Geography | `nouns/geography.txt` |
| School/Education | *(Not found in directory)* |
| Weather | *(Not found in directory)* |
| Fruits | `nouns/fruit.txt` |

**Naming Convention:** Flat structure, kebab-case filenames, one word per line.

**Notable Gap:** Ocean/sea-specific file not found. Consider aggregating from related categories or creating custom ocean wordlist.

---

## TOPIC 2: Kaikki.org / Wiktionary Extracted JSON

**Official Site:** https://kaikki.org

**Recommended Download:**
- **URL:** https://kaikki.org/dictionary/rawdata.html → `raw-wiktextract-data.jsonl`
- **Format:** JSONL (one JSON object per line)
- **File Size:**
  - Uncompressed: 20.4GB
  - Compressed (.gz): 2.4GB
- **Deprecation Status:** Earlier JSONL file (2.7GB) is deprecated. Use raw-wiktextract-data.jsonl instead.
- **License:** Creative Commons (Wiktionary-derived, CC BY-SA implied, per kaikki.org policy)

**JSON Entry Fields (from Wiktextract):**
```
{
  "word": "string",
  "lang": "English",
  "lang_code": "en",
  "pos": "noun|verb|adjective|...",
  "senses": [
    {
      "glosses": ["definition text"],
      "tags": ["countable", "obsolete", "figuratively", ...]
    }
  ],
  "forms": [...],
  "sounds": [...],
  "translations": [...],
  "derived": [...],
  "categories": [...],
  "wikipedia": [...]
}
```

**Key Field:** `senses[].glosses[]` contains definition text suitable for clue extraction.

**Pipeline Consideration:** Process JSONL streaming rather than loading entire 20.4GB into memory.

---

## TOPIC 3: Wiktionary Gloss Cleaning for Crossword Clues

**Patterns to Clean:**
- Metadata tags: `(countable)`, `(uncountable)`, `(transitive)`, `(obsolete)`, `(archaic)`
- Self-referential prefixes: `A type of X`, `One who X`, `That which X`
- Wiki markup: `[[word]]`, `{{template}}`, HTML entities `&nbsp;`, `&mdash;`
- Parenthetical context: `(in botany)`, `(physics)`, `(computing)`
- Redundant expansions: `"The act of [word-ing]"` when shorter form exists

**Standard Regex Cleaning Pipeline:**
```
1. Remove metadata: /\((?:countable|uncountable|transitive|intransitive|obsolete|archaic)\)/g
2. Remove wiki links: /\[\[(\w+)\]\]/g → replace with $1
3. Remove wiki templates: /\{\{[^}]+\}\}/g
4. Remove HTML entities: Replace &nbsp; → space, &mdash; → dash, &quot; → "
5. Remove parenthetical context: /\([^)]{3,}\)/g (optional based on gloss length)
6. Trim whitespace and limit to 8 words: split(/\s+/).slice(0, 8).join(' ')
```

**Self-Referential Detection:**
- Extract answer word from crossword grid slot
- Check if gloss contains answer word (case-insensitive)
- Reject clues where answer appears in first 3 words of gloss
- Example: word="cat", gloss="A cat is an animal" → reject (self-ref)

**Result Target:** ≤8 words, no metadata, no self-references, no wiki markup.

---

## TOPIC 4: SwiftUI Crossword Grid — Black Cell Implementation

**Cell Model Pattern:**

Option A (Sentinel String):
```swift
struct CrosswordCell {
  var value: String?  // nil = empty, "" = black cell, "A" = letter
  var isBlack: Bool { value == "" }
  var isEmpty: Bool { value == nil }
}
```

Option B (Enum):
```swift
enum CellType {
  case letter(String)
  case empty
  case black
}
```

Option C (Optional with Sentinel):
```swift
struct CrosswordCell {
  var value: String?  // nil = empty, "#" = black cell sentinel
  var isBlack: Bool { value == "#" }
}
```

**Recommended:** Option B (enum) provides type safety and clarity.

**SwiftUI: Disable Tap on Black Cells**

```swift
Button(action: { handleCellTap(row, col) }) {
  Text(cell.displayText)
    .frame(width: 40, height: 40)
    .background(cell.isBlack ? Color.black : Color.white)
    .disabled(cell.isBlack)  // Disable interaction
    .allowsHitTesting(!cell.isBlack)  // Prevent tap passthrough
}
```

**Key Modifiers:**
- `.disabled(condition)` — disables button state, grays appearance
- `.allowsHitTesting(false)` — allows taps to pass through to views behind

**Grid Layout Pattern:**
```swift
VStack {
  ForEach(0..<grid.count, id: \.self) { row in
    HStack(spacing: 0) {
      ForEach(0..<grid[row].count, id: \.self) { col in
        CellView(cell: grid[row][col], row: row, col: col)
      }
    }
  }
}
```

**Black Cell Styling:**
- Black cells should not be tappable
- Use `.isUserInteractionEnabled = false` on black cells (UIView level)
- Or conditionally render as non-interactive `Rectangle()` instead of `Button`

**Preferred Pattern:**
```swift
if cell.isBlack {
  Rectangle()
    .fill(.black)
    .frame(width: 40, height: 40)
} else {
  Button(...) { ... }
}
```

---

## Summary Table

| Topic | Key Finding | Source |
|-------|------------|--------|
| **Wordlists** | 78 noun categories; use nouns/*.txt; astronomy.txt exists; ocean.txt missing | [GitHub](https://github.com/imsky/wordlists) |
| **Wiktionary JSON** | raw-wiktextract-data.jsonl (20.4GB); JSONL format; CC BY-SA license; use senses[].glosses[] | [Kaikki.org](https://kaikki.org/dictionary/rawdata.html) |
| **Gloss Cleaning** | Remove metadata/markup; limit to 8 words; detect self-references via answer match | [Regex standards](https://helgeklein.com/blog/regex-cheat-sheet-regular-expressions-for-cleaning-up-html/) |
| **SwiftUI Grid** | Use enum or string sentinel for cell type; .disabled() + .allowsHitTesting(false) on black cells | [SwiftUI Docs](https://www.hackingwithswift.com/quick-start/swiftui/how-to-disable-taps-for-a-view-using-allowshittesting) |

---

## Implementation Recommendations

1. **Wordlist Source:** Prefer imsky/wordlists for lightweight, curated categories. Create custom ocean.txt by combining water, fish, and geography files if needed.

2. **Dictionary Pipeline:**
   - Stream JSONL from kaikki.org (don't load all 20GB)
   - Process in batches: filter by POS (noun, verb, adjective), extract glosses
   - Apply cleaning regex pipeline, truncate to 8 words
   - Store in indexed format (SQLite or flat JSON by word)

3. **Clue Validation:**
   - After cleaning, check clue length (fail if >8 words or <3 words)
   - Check clue uniqueness (avoid duplicates per word)
   - Flag and review self-referential clues before puzzle generation

4. **Grid Model:**
   - Use enum-based cell type for type safety
   - Separate data model (grid state) from view model (UI rendering)
   - Black cells: render as static Rectangle, not Button

---

## Unresolved Questions

1. Does imsky/wordlists have ocean/sea-specific file, or must we aggregate from existing categories?
2. What is the exact full URL for kaikki.org English JSONL download (relative path given, needs absolute URL)?
3. What gloss length threshold triggers rejection (8 words, 10 words, 100 chars)?
4. Should self-referential detection also include synonyms (e.g., word="cat", gloss="feline")?

---

**Sources:**
- [GitHub - imsky/wordlists](https://github.com/imsky/wordlists)
- [Kaikki.org Dictionary Raw Data](https://kaikki.org/dictionary/rawdata.html)
- [Wiktextract GitHub](https://github.com/tatuylonen/wiktextract)
- [SwiftUI allowsHitTesting](https://www.hackingwithswift.com/quick-start/swiftui/how-to-disable-taps-for-a-view-using-allowshittesting)
- [Regex HTML Cleaning](https://helgeklein.com/blog/regex-cheat-sheet-regular-expressions-for-cleaning-up-html/)
