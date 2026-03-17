# Phase 02 — ViewModel

## Context Links
- [plan.md](plan.md) — overview
- [phase-01](phase-01-models-and-engine.md) — models this VM uses
- Pattern ref: `SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift`

## Overview
- **Priority:** P1
- **Status:** pending
- Central game logic controller. Manages cell selection, direction toggling, letter input, cursor advancement, hint system (check/reveal letter/reveal word), undo, timer, ad integration, auto-save.

## Key Insights
- Crossword has directional selection (across/down) — tapping already-selected cell toggles direction
- Cursor auto-advances after input in current word direction
- Three hint types with different costs: check letter (1), reveal letter (1), reveal word (3)
- Diamond hint: reveal letter for 1 diamond (reuse `DiamondReward.undoCost`)
- Undo is FREE — stack of board snapshots, max depth 20
- No mistake limit — crosswords don't penalize wrong entries
- GamePhase: playing/paused/won/needsHintAd (reuse existing enum, no lost/needsMistakeResetAd)

## Requirements

### Published State
- `puzzle: CrosswordPuzzle`
- `boardState: CrosswordBoardState`
- `selectedRow: Int?`, `selectedCol: Int?`
- `selectedDirection: ClueDirection` (.across default)
- `activeClue: CrosswordClue?` (computed from selection + direction)
- `gamePhase: GamePhase` (reuse existing enum)
- `elapsedSeconds: Int`
- `hintsRemaining: Int`
- `hintsUsedTotal: Int`
- `undoStack: [CrosswordBoardSnapshot]`
- `hintsGrantedOnWin: Int`
- `goldEarnedOnWin: Int`

### Core Actions
1. **selectCell(row:col:)** — if same cell, toggle direction; else select + determine direction from clue membership
2. **inputLetter(_ char: Character)** — place letter, advance cursor in direction, push undo snapshot
3. **deleteLetter()** — erase current cell, move cursor backward
4. **undo()** — pop snapshot, restore board state (FREE, no cost)
5. **checkLetter()** — cost 1 hint; highlight green (correct) or red (wrong) for 1.5s
6. **revealLetter()** — cost 1 hint; permanently fill correct letter, mark isRevealed
7. **revealWord()** — cost 3 hints; reveal all unrevealed cells in active clue's word
8. **revealLetterWithDiamond()** — spend 1 diamond via DiamondService, then revealLetter()
9. **requestHintAd()** — transition to needsHintAd when hints exhausted
10. **grantHintsAfterAd()** — grant rewardedHintAmount, resume playing
11. **pause() / resume()**
12. **restart()**

### Cursor Logic
- After input: advance to next empty cell in word direction
- After delete: move backward to previous non-revealed cell
- Skip revealed cells and black cells

### Win Detection
- After each input/reveal, call `CrosswordValidator.isSolved()`
- On win: stop timer, log analytics, earn gold, grant level-complete hints, show interstitial

### Auto-Save
- Debounced 500ms after each board change (same pattern as Sudoku)
- Save full `CrosswordGameState` to persistence

## Related Code Files
- **Create:** `SmartGames/Games/Crossword/ViewModels/CrosswordGameViewModel.swift`

## Implementation Steps
1. Create `CrosswordGameViewModel.swift` as `@MainActor final class: ObservableObject`
2. Define all `@Published` properties
3. Inject services: persistence, analytics, sound, haptics, ads, goldService, diamondService, monetizationConfig
4. Implement init with saved-state restoration (same pattern as SudokuGameViewModel)
5. Implement selectCell with direction toggling
6. Implement inputLetter with cursor advancement
7. Implement deleteLetter with backward cursor
8. Implement undo (free, pop snapshot)
9. Implement checkLetter (1 hint, visual feedback via published flag)
10. Implement revealLetter (1 hint, mark isRevealed)
11. Implement revealWord (3 hints, reveal all in word)
12. Implement revealLetterWithDiamond (1 diamond spend)
13. Implement hint ad flow (needsHintAd phase, grant after ad)
14. Implement timer (async Task, 1s interval)
15. Implement auto-save (debounced 500ms)
16. Implement win check + rewards (gold, hints, analytics, interstitial)
17. Implement pause/resume/restart
18. Keep file under 200 lines — if exceeded, split actions into `CrosswordGameViewModel+Actions.swift`
19. Compile check

## Todo List
- [ ] CrosswordGameViewModel with published state
- [ ] Service injection + init with save restoration
- [ ] Cell selection + direction toggling
- [ ] Letter input + cursor advancement
- [ ] Delete + backward cursor
- [ ] Undo (free, max 20 depth)
- [ ] Check letter hint (1 cost, visual feedback)
- [ ] Reveal letter hint (1 cost, permanent)
- [ ] Reveal word hint (3 cost)
- [ ] Diamond reveal letter
- [ ] Hint ad flow
- [ ] Timer + auto-save
- [ ] Win detection + rewards
- [ ] Pause / resume / restart
- [ ] Split to +Actions if >200 lines
- [ ] Compile check

## Success Criteria
- All game actions work correctly
- Direction toggling on re-tap functions properly
- Cursor advances/retreats correctly, skipping blacks and revealed cells
- Undo restores board state without cost
- Hints deduct correct amounts
- Diamond spend calls DiamondService.spend()
- Win triggers gold + hint rewards + analytics
- Auto-save persists and restores correctly
