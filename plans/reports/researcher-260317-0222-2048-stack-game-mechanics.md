# 2048 & Stack Game Mechanics Research Report

**Date:** 2026-03-17
**Scope:** Original 2048 rules, Stack variant (column-drop), merge mechanics, scoring, color schemes
**Target:** iOS/Swift implementation guide for Drop-Rush-like column-based 2048

---

## 1. Original 2048 Game Mechanics (Gabriel Cirulli)

### Core Rules
- **Grid:** 4×4 tile grid (16 cells)
- **Objective:** Combine tiles to reach 2048 or beyond
- **Starting State:** Two random tiles (2 or 4) placed on empty board
- **Spawn Rules:** After each move, one new tile spawns:
  - 90% chance: value 2
  - 10% chance: value 4
  - Spawns in a random empty cell

### Movement & Merging
- Player swipes in 4 directions (up, down, left, right)
- All tiles slide in that direction until hitting edge or another tile
- **Merge Condition:** Two tiles of **identical value** touching merge into one tile worth double
- **Critical:** A tile merged in this move **cannot merge again** in the same move
- **Three-in-a-row behavior:** If 3×2 and 2 are in a row and swiped:
  - Only the 2 farthest along slide direction merge together
  - Third tile stops before them
  - Example: [2, 2, 2, empty] swiped right → [empty, 2, 2, 4]
- **Four matching tiles:** [2, 2, 2, 2] swiped right → [empty, empty, 4, 4]

### Scoring
- Score increases by the **value of the newly merged tile**
- Merging a 2+2=4 awards 4 points
- Merging 1024+1024=2048 awards 2048 points
- Score accumulates throughout game

### Game Over Condition
- **Lose:** Board fills completely with no possible moves (no adjacent tiles of equal value, no empty cells)
- **Win State:** Reaching 2048 tile (optional—can continue playing)

**Source:** [2048 by Gabriele Cirulli](https://gabrielecirulli.github.io/2048/), [Wikipedia](https://en.wikipedia.org/wiki/2048_(video_game))

---

## 2. Stack Variant: Column-Drop Mechanics

The Stack variant transforms 2048 from a directional-slide game into a **Tetris-like column-drop game** with vertical merges.

### Grid & Layout
- **Grid:** 5 columns, variable height (typically 8+ rows)
- **Input:** Player taps a column to drop the current tile
- **Physics:** Tile falls via gravity until hitting:
  - Bottom of grid
  - Another tile in same column

### Tile Spawning & Control
- **Current Tile Display:** Shown at bottom center, ready to drop
- **Next Tile Preview:** Usually shown to right/left of current tile
- **Spawn Pattern:** Random value (2, 4, 8, etc.) each turn
- **Player Action:** Tap column header → drops current tile → next tile becomes current

### Merge Rules (Vertical)
**When a tile lands, immediately check for merges:**
1. **Same-value tiles** vertically adjacent in same column merge
2. Merged tile doubles in value
3. **No chain merges** (unlike some variants)—a single column-drop causes at most one merge per column

### Horizontal Merges (Advanced Variant)
Some variants support **horizontal merges** when tiles of equal value are adjacent horizontally:
- Not standard in all versions
- Adds strategic depth: tiles can merge sideways

### Score & Currency System
- **Points:** Awarded for each merge (tile value = points awarded)
  - Example: 4+4=8 awards 8 points
  - Does NOT follow original 2048 scoring (which awards merged-result value)
- **Currency (Diamonds/Gold):**
  - Earned through gameplay (accumulated per-game or per-level)
  - Used to unlock power-ups

### Power-Ups
- **Hammer:** Destroy one tile (instant removal, clears space)
- **Shuffle:** Get a new random tile (swap current tile for fresh random)
- **Cost:** Diamonds/Gold currency from shop

### Game Over Condition
- **Lose:** Column fills to top (no room to drop new tile)
- **Alternative:** Move limit reached (e.g., "50 moves to clear board")

**Sources:** [Drop 2048 App Store](https://apps.apple.com/us/app/drop-2048-tile-merge-puzzle/id1448133522), [2048: Drop And Merge](https://aleksdev.github.io/aleksdev.github.io/2048.html), [Drop Merge Game](https://ozogames.com/game/drop-merge/)

---

## 3. Tile Value & Color Scheme

### Standard 2048 Color Palette (Hex Values)

| Value | Hex Color | RGB Description | Visual Appearance |
|-------|-----------|-----------------|-------------------|
| 2     | #eee4da   | Light beige      | Neutral base      |
| 4     | #ede0c8   | Warm beige       | Warm shift        |
| 8     | #f2b179   | Light orange     | Orange begins     |
| 16    | #f59563   | Medium orange    | Warmer orange     |
| 32    | #f67c5f   | Orange-red       | Red tones start   |
| 64    | #f65e3b   | Bold red         | Bright red        |
| 128   | #edcf72   | Golden yellow    | Golden phase      |
| 256   | #edcc61   | Darker yellow    | Yellow/gold       |
| 512   | #edc850   | Gold             | Rich gold         |
| 1024  | #edc53f   | Bright gold      | Bright special    |
| 2048  | #edc22e   | Golden highlight | Special milestone |
| 4096+ | (varies)  | Extended scheme  | Game-specific     |

### Color Logic
- **Low values (2–4):** Neutral beige tones
- **Mid values (8–64):** Warm orange-to-red gradient (engagement)
- **High values (128–512):** Yellow-gold transition (achievement)
- **Milestone (1024+):** Bright gold (special/milestone effect)

### Text Contrast
- **Dark text (#776e65):** Tiles 2–4
- **Light text (#f9f6f2):** Tiles 8 and higher
- Alternative: Pure white or black depending on background luminance

**Source:** [2048 Color Scheme Research](https://github.com/gabrielecirulli/2048), [2048 PANTONE](https://0x0800.github.io/2048-PANTONE/), [Adobe Color Theme](https://color.adobe.com/2048-Tiles-color-theme-3940536/)

---

## 4. Merge Chain Mechanics (Deep Dive)

### Original 2048: No Chain Merges
In the classic game:
- A single move causes all possible merges simultaneously
- **But:** Each tile can merge **at most once per move**
- Tiles merged in one move cannot merge again in same move

**Example:**
```
[2, 2, 2, 2] swiped right
→ Step 1: All tiles slide right → [2, 2, 2, 2]
→ Step 2: Merge from farthest:
    - Rightmost pair (2+2) → 4
    - Leftmost pair (2+2) → 4
→ Result: [empty, empty, 4, 4] (NOT [empty, 8])
```

**Why:** Prevents cascading and keeps game state deterministic per move.

### Stack Variant: Single-Point Merge
When a tile drops into a column:
1. Check if tile matches value directly below
2. If yes: merge (no chain)
3. If no: rest in place
4. **Gravity settles** other tiles downward if column changed

**Does NOT trigger:**
- Horizontal merges from vertical drop (separate mechanic)
- Chain reactions of previous merges

### Advanced Variants: Chain Reactions
Some 2048 variants support **cascade merges** (like Match-3 games):
- When a tile lands and merges, check if NEW tile value creates new merges below
- Repeat until no more merges possible
- Adds complexity; not standard

**Your codebase (Drop Rush):** Uses single-tap destruction model (not 2048 merges), so merge logic differs significantly.

**Sources:** [2048 Merge Algorithm](https://saturncloud.io/blog/tile-merging-algorithm-in-the-2048-game-a-comprehensive-guide/), [Steven.codes - 2048 Merge](https://steven.codes/blog/cs10/2048-merge/), [Supermerging 2048](https://www.cesoid.com/2048/supermerging)

---

## 5. Stack Variant Implementation Details

### Column State Management
```
Column[i] = [Tile, Tile, ..., Tile, empty, empty]
            ↑                         ↑
          bottom                    top (room to drop)
```

- Tiles settle via gravity (no "floating" tiles)
- Each column tracks tiles from bottom up
- Empty spaces always at top in column

### Drop Sequence
1. Player selects column index (0–4)
2. Check if column has empty space at top
3. If full: deny action or trigger game-over
4. Drop tile from top, falls to first occupied tile
5. Land on that tile (or column bottom)
6. Check merge: if top tile == tile below → merge
7. Compact column (shift tiles down)
8. Spawn next tile

### Merge Implementation
```swift
// Pseudo-code for column merge
func attemptMerge(in column: [Tile]) -> [Tile] {
    var result = column
    var i = result.count - 1  // start from bottom

    while i > 0 {
        if result[i].value == result[i-1].value {
            result[i].value *= 2
            result.remove(at: i-1)
            score += result[i].value  // award points
            i -= 1  // don't check merged tile again
        }
        i -= 1
    }
    return result
}
```

### Scoring in Stack
- **Per merge:** Award the merged tile value as points
  - 4+4=8 → +8 points
- **Combo:** Sometimes bonus multiplier for consecutive merges
- **Currency:** Separate from points; earned slower (e.g., 1 diamond per 500 points)

---

## 6. Key Differences: Original 2048 vs. Stack Variant

| Aspect | Original 2048 | Stack Variant |
|--------|---------------|---------------|
| **Grid** | 4×4 fixed | 5 columns × N rows |
| **Input** | Swipe 4 directions | Tap column (1D) |
| **Physics** | Slide to edge | Drop via gravity |
| **Merge Trigger** | Directional slide | Tile landing |
| **Merges Per Move** | Multiple (all directions) | Single column only |
| **Chain Merges** | No (each tile: ≤1 per move) | Typically no (variant) |
| **Game Over** | Board full + no moves | Top row filled |
| **Scoring** | Merged tile value | Same logic |
| **Currency** | None (original) | Diamonds/Gold for power-ups |

---

## 7. Recommended Implementation Approach (Swift/SwiftUI)

### Architecture
```
Game/
├── Engine/
│   ├── GridState (board + logic)
│   ├── MergeProcessor (merge detection/execution)
│   └── GameRules (win/lose conditions)
├── Models/
│   ├── Tile (value, position, ID)
│   ├── GameEvent (merge, spawn, gameOver)
│   └── GameConfig (max_moves, power-up costs)
├── ViewModels/
│   ├── GameViewModel (state binding, input dispatch)
│   └── AnimationController (merge animations)
└── Views/
    ├── GridView (column rendering)
    ├── TileView (tile + value + color)
    └── HUDView (score, currency, power-ups)
```

### Key Implementation Notes

1. **Immutable State:** Store game board as value type (struct), use copy-on-write for efficiency
2. **Event-Driven:** Emit `GameEvent` for each action; ViewModel subscribes to drive UI
3. **Animations:** Separate from logic; animate tile drop, merge, destruction asynchronously
4. **Merge Algorithm:** Linear time; scan column once for merges, update values, compact
5. **Color Mapping:** Pre-compute `[Int: Color]` dictionary; lookup during render
6. **Gravity:** On tile land or power-up (Hammer), re-compact column from bottom up

### Scoring Formula
```swift
func scoreForMerge(baseValue: Int, comboMultiplier: CGFloat = 1.0) -> Int {
    return Int(CGFloat(baseValue) * comboMultiplier)
}
```

---

## Summary: Key Takeaways

| Question | Answer |
|----------|--------|
| **Tiles merge multiple times in one move?** | No (original 2048 & standard Stack). Each tile ≤1 merge per move. |
| **How merges work in column-drop?** | Tile lands → check if matches tile below → merge if yes → compact. Single pass. |
| **Color for 2048 tile?** | #edc22e (golden highlight) or #edc53f (bright gold). |
| **Merge chain mechanics?** | Standard: no chains. Variants exist (rare). Avoid complexity unless design requires. |
| **Scoring model?** | Award merged-tile value as points. Use combo multipliers for streaks. |
| **Power-up costs?** | Use separate currency (Diamonds/Gold); costs vary (Hammer: 50, Shuffle: 30). |

---

## Unresolved Questions

1. **Drop Rush context:** Your existing Drop Rush is symbol-matching (not 2048-style). Will new Stack game be separate module or evolution?
2. **Currency integration:** Should Stack use existing Gold system or new Diamonds currency?
3. **Power-up balancing:** What are target frequencies for power-up usage? (e.g., 1 Hammer per 50 points?)
4. **Merge animations:** Priority—simultaneous all merges or sequential per column?
5. **Board height:** Fixed (8 rows) or variable? Affects difficulty scaling.
6. **Horizontal merges:** Include or exclude? (adds ~20% complexity)

---

**Report Generated:** 2026-03-17 / Researcher Agent
**Knowledge Cutoff:** February 2025
