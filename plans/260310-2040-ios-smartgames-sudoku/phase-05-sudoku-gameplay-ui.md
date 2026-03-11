# Phase 05 — Sudoku Gameplay UI

**Priority:** Critical | **Effort:** L | **PRs:** PR-05, PR-06, PR-07

Split into 3 PRs for reviewability.

---

## PR-05 — Board UI + Cell Rendering + Selection Highlighting

### Goal
Render the 9x9 board with correct grid lines, cell highlight states, and selection logic. No number input yet.

---

### Screen: SudokuLobbyView

Reference: Screenshot 2 — blurred background, "Sudoku / Unlock your brain." title, Daily Challenge card, bottom sheet with difficulty selector.

```
┌──────────────────────────────────┐
│  ← [back]              [🏆]      │
│                                  │
│   ┌──────────────────────────┐   │
│   │  📅 Daily Challenge      │   │  ← card (Phase 2)
│   │     Mar 10               │   │
│   │      [PLAY]              │   │
│   └──────────────────────────┘   │
│                                  │
│         Sudoku                   │
│      Unlock your brain.          │
│                                  │
└──────────────────────────────────┘
        ▲── bottom sheet ──▲
        │    NEW GAME       │
        │  ≡ Easy           │
        │  ≡≡ Medium        │
        │  ≡≡≡ Hard         │
        │  ≡≡≡≡ Expert      │
        └───────────────────┘
```

Bottom sheet is a native SwiftUI `.sheet` with `presentationDetents([.medium])`.

---

### Screen: SudokuGameView Layout

Reference: Screenshots 3 & 4

```
┌──────────────────────────────────┐
│  ←          ‖ Pause             │  ← toolbar (back + pause)
│                                  │
│  Mistakes: 0/3  Easy    00:02   │  ← stats bar
│                                  │
│  ┌──────────────────────────┐   │
│  │                          │   │
│  │    9x9 Sudoku Board      │   │  ← SudokuBoardView
│  │                          │   │
│  └──────────────────────────┘   │
│                                  │
│  [↩ Undo] [⌫ Erase] [✏ Pencil] [💡 Hint] │  ← SudokuToolbarView
│                                  │
│  [1] [2] [3] [4] [5] [6] [7] [8] [9]     │  ← SudokuNumberPadView
│                                  │
└──────────────────────────────────┘
```

---

### SudokuBoardView

Grid rendering rules:
- 9x9 grid of `SudokuCellView`
- Thin lines between cells (0.5pt, gray)
- Thick lines between 3x3 boxes (2pt, dark gray)
- Board fills available width, aspect ratio 1:1

```swift
struct SudokuBoardView: View {
    @ObservedObject var viewModel: SudokuGameViewModel

    var body: some View {
        // LazyVGrid with fixed columns, or manual Grid
        // Use Grid (iOS 16+) for precise border control
    }
}
```

---

### SudokuCellView — Highlight States

Visual priority order (highest wins when states overlap):

| Priority | State | `CellHighlightState` | Background | Text Color | Notes |
|----------|-------|----------------------|------------|------------|-------|
| 1 | Error | `.error` | Light red `#FFEBEE` | Red | Wrong player placement |
| 2 | Selected (filled) | `.selected` | Deep blue `#1565C0` | White | Pre-filled or player-filled cell tapped |
| 3 | Selected (empty) | `.selectedEmpty` | Yellow `#FFF9C4` | Dark gray | Editable empty cell tapped — keypad active |
| 4 | Same number | `.sameNumber` | Teal `#B2EBF2` | Dark gray | Same digit as selected cell's value |
| 5 | Related | `.related` | Light blue `#E3F2FD` | Dark gray | Same row / col / 3x3 box as selected |
| 6 | Default | `.normal` | White / clear | Dark gray | No selection context |
| — | Given text style | (modifier, not state) | — | Black, semibold | `isGiven == true` |
| — | Pencil marks | (modifier, not state) | Clear | Blue, small | Candidate marks inside cell |

---

### Interaction Rules — Cell Tap

#### Tapping a pre-filled digit cell (`cell.isGiven == true` OR `cell.isPlayerFilled == true`)

1. Set `selectedCell = (row, col)` → state `.selected`
2. Highlight row/col/box peers → `.related`
3. Highlight all board cells with the same digit → `.sameNumber`
4. **Keypad is NOT activated** — `placeNumber` is a no-op for given cells (`guard !cell.isGiven else { return }`)
5. Number pad button for the selected digit is visually highlighted (same as same-number highlight)

> Visual hierarchy: selected cell (deep blue, strongest) > same-number cells (teal) > related cells (light blue)

#### Tapping an empty editable cell (`cell.isEmpty == true`)

1. Set `selectedCell = (row, col)` → state `.selectedEmpty`
2. Highlight row/col/box peers → `.related` (light blue)
3. No same-number highlight (cell has no value yet)
4. **Keypad IS activated** — next number pad tap places digit in this cell
5. Selected cell (yellow) is visually distinct from related cells (light blue) — never the same color

> Visual hierarchy: selected cell (yellow, strongest) > related cells (light blue)

---

### Interaction Rules — Keypad Input

```
placeNumber(_ n: Int):
  guard selectedCell != nil else { return }   // no-op: nothing selected
  guard !cell.isGiven else { return }         // no-op: pre-filled cell selected
  // proceed with pencil or value placement
```

| Scenario | Expected Behavior |
|----------|-------------------|
| No cell selected | Keypad tap → no-op (ignored) |
| Pre-filled cell selected | Keypad tap → no-op (ignored) |
| Player-filled cell selected | Keypad tap → replaces value (or toggles pencil mark) |
| Empty editable cell selected | Keypad tap → places digit (or adds pencil mark) |

**These guards are enforced in `SudokuGameViewModel.placeNumber()` — NOT in the view layer.**

---

### State Model — `CellHighlightState`

```swift
enum CellHighlightState {
    case normal        // no selection context
    case selected      // tapped cell — has a value (given or player-filled)
    case selectedEmpty // tapped cell — empty, editable; keypad now active
    case related       // same row / col / 3x3 box as selected
    case sameNumber    // contains same digit as the selected cell's value
    case error         // wrong player placement
}
```

`highlightState(for:col:)` priority logic:
1. If this cell is the selected cell → `.selectedEmpty` if empty, `.selected` if has value
2. If `cell.hasError` → `.error`
3. If selected cell has a value AND this cell has the same value → `.sameNumber`
4. If this cell is a peer of selected (row / col / box) → `.related`
5. Otherwise → `.normal`

---

```swift
struct SudokuCellView: View {
    let cell: SudokuCell
    let highlightState: CellHighlightState
    let onTap: () -> Void
}
```

**Pencil marks layout:** 3x3 mini grid inside cell showing candidate numbers in small font.

---

### Files for PR-05

| File | Action |
|------|--------|
| `Games/Sudoku/Views/SudokuLobbyView.swift` | Create |
| `Games/Sudoku/Views/SudokuGameView.swift` | Create (layout scaffold) |
| `Games/Sudoku/Views/SudokuBoardView.swift` | Create |
| `Games/Sudoku/Views/SudokuCellView.swift` | Create |
| `Games/Sudoku/ViewModels/SudokuLobbyViewModel.swift` | Create |
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Create (selection logic only) |

### Acceptance Criteria PR-05
- [ ] Board renders correct 9x9 grid with thick 3x3 box borders
- [ ] Tapping a pre-filled cell → `.selected` (deep blue), peers → `.related` (light blue), same-digit cells → `.sameNumber` (teal)
- [ ] Tapping an empty editable cell → `.selectedEmpty` (yellow), peers → `.related` (light blue); selected cell color is distinct from related cells
- [ ] Tapping pre-filled cell does NOT enable keypad (placeNumber is a no-op for given cells)
- [ ] Tapping with no cell selected → keypad tap is a no-op
- [ ] Visual priority: selected > same-number > related > normal (no state bleed)
- [ ] Given cells display semibold black text; empty cells display gray
- [ ] Lobby bottom sheet shows 4 difficulty options
- [ ] Board is square and fills screen width on all iPhone sizes

---

## PR-06 — Number Input, Undo, Eraser, Pencil, Hint System

### Goal
Wire up number input, tool buttons, game logic integration, mistake tracking.

---

### SudokuNumberPadView

9 circular buttons, 1–9.
- Numbers already fully placed on board → grey/dimmed (optional UX improvement)
- Tap number → places in selected cell (or adds pencil mark in pencil mode)

```swift
struct SudokuNumberPadView: View {
    let onNumberTap: (Int) -> Void
    let completedNumbers: Set<Int>  // numbers with all 9 placed → dimmed
}
```

---

### SudokuToolbarView

4 tool buttons in a row:

| Button | Icon | Action |
|--------|------|--------|
| Undo | `arrow.uturn.backward` | Undo last move |
| Eraser | `eraser` | Clear selected cell value + pencil marks |
| Pencil | `pencil` | Toggle pencil mode (active state indicator) |
| Hint | `lightbulb` + play overlay | Use hint or trigger rewarded ad |

Hint button shows a small `▶` overlay when hinting requires watching an ad.

---

### SudokuGameViewModel — Full State

```swift
@MainActor
final class SudokuGameViewModel: ObservableObject {
    // State
    @Published var puzzle: SudokuPuzzle
    @Published var selectedCell: CellPosition?
    @Published var isPencilMode: Bool = false
    @Published var gamePhase: GamePhase = .playing
    @Published var elapsedSeconds: Int = 0
    @Published var mistakeCount: Int = 0
    @Published var hintsRemaining: Int
    @Published var undoStack: [BoardSnapshot] = []

    // Actions
    func selectCell(row: Int, col: Int)
    func placeNumber(_ n: Int)
    func eraseSelected()
    func undo()
    func useHint()
    func togglePencilMode()
    func pause()
    func resume()
    func restart()

    // Internal
    private func autoSave()
    private func checkWin()
    private func checkMistakeLimit()
    private func highlightStates() -> [[CellHighlightState]]
}

enum GamePhase {
    case playing, paused, won, lost  // lost = 3 mistakes reached
}

struct BoardSnapshot: Codable {
    let board: [[SudokuCell]]
    let mistakeCount: Int
}
```

---

### Move Logic

When `placeNumber(_ n: Int)` called:
1. If no selected cell → ignore
2. If selected cell is given → ignore
3. If pencil mode → toggle pencil mark, return
4. If value matches solution[row][col]:
   - Set cell.value = n, clear pencil marks
   - Play `.tap` sound + `.medium` haptic
   - Auto-clear pencil marks for same number in row/col/box
   - Check win condition
5. If value wrong:
   - Set cell.value = n (show red), cell.hasError = true
   - Increment mistakeCount
   - Play `.error` sound + `.error` haptic
   - Check mistake limit (3 → game over)
6. Push `BoardSnapshot` to undoStack (max depth 50)
7. Auto-save

---

### Undo Logic

- Pop last `BoardSnapshot` from undoStack
- Restore board state
- Decrement mistakeCount if last move was an error
- Play `.tap` haptic

---

### Hint Logic

```
hintsRemaining > 0:
  → reveal one cell (solution value), decrement hintsRemaining
  → play `.hint` sound

hintsRemaining == 0:
  → show "Watch ad for hints?" dialog
  → if accepted → show AdsService.showRewardedAd()
  → on reward → hintsRemaining += 3
```

---

### Files for PR-06

| File | Action |
|------|--------|
| `Games/Sudoku/Views/SudokuNumberPadView.swift` | Create |
| `Games/Sudoku/Views/SudokuToolbarView.swift` | Create |
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Extend (full logic) |

### Acceptance Criteria PR-06
- [ ] Keypad tap fills the selected empty editable cell with the chosen digit
- [ ] Keypad tap on a pre-filled selected cell → no-op (cell value unchanged, no crash)
- [ ] Keypad tap with no cell selected → no-op (no crash, no state change)
- [ ] Player-filled cell re-tap + keypad → replaces value (not a given-cell guard)
- [ ] Pencil mode toggles and draws 3x3 mini marks inside cell
- [ ] Eraser clears value and pencil marks from selected editable cell; no-op on given cells
- [ ] Undo restores previous board state
- [ ] Mistake counter increments on wrong placement
- [ ] Hint reveals correct value and decrements counter
- [ ] When hints = 0, ad prompt appears

---

## PR-07 — Game State Machine, Timer, Win/Lose/Pause

### Goal
Complete the game lifecycle: timer, pause overlay, win screen, lose screen, restart.

---

### Game State Machine

```
[Hub] → [Lobby] → [Playing] ⇄ [Paused]
                      ↓           ↓
                   [Won]      [Lost (3 mistakes)]
                      ↓           ↓
                  [Next / Hub]  [Retry / Hub]
```

---

### Timer

```swift
// In SudokuGameViewModel
private var timerTask: Task<Void, Never>?

func startTimer() {
    timerTask = Task {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            elapsedSeconds += 1
        }
    }
}

func pauseTimer() { timerTask?.cancel() }
func resumeTimer() { startTimer() }
```

Display: `MM:SS` format. Counts up from 0.

---

### Pause Overlay

Full-screen dimmed overlay with:
- "PAUSED" label
- Resume button
- Restart button
- Back to hub button

Board hidden when paused (prevents cheating).

---

### SudokuWinView

Shown modally over game when `gamePhase == .won`:

```
┌──────────────────────────────┐
│         🎉 Puzzle Solved!    │
│                              │
│    ⏱  Time: 02:34           │
│    ⭐⭐⭐  (based on time)   │
│    ❌  Mistakes: 1/3        │
│                              │
│    [Next Puzzle]             │
│    [Back to Menu]            │
└──────────────────────────────┘
```

**Star rating formula (Easy as example):**
- ⭐⭐⭐: No mistakes + time < 5 min
- ⭐⭐: ≤1 mistake OR time < 10 min
- ⭐: Completed

Win triggers: confetti animation (SwiftUI particles or simple scale+fade), `.win` sound, `.success` haptic.

**After win:** interstitial ad candidate (light, only if ad ready, max 1 per session initially).

---

### Lose State (3 Mistakes)

Alert or full-screen overlay:
- "Game Over — 3 mistakes reached"
- [Try Again] — restart same puzzle
- [New Game] — go to lobby
- [Watch Ad to Continue] → rewarded ad, reset mistake counter to 2

---

### Scene Phase Handling

```swift
.onChange(of: scenePhase) { phase in
    if phase == .background || phase == .inactive {
        viewModel.pause()
        viewModel.autoSave()
    }
}
```

---

### Save / Resume

On app relaunch with saved game:
- Hub shows "Resume" badge on Sudoku card
- Sudoku lobby shows "Resume Game" option above "NEW GAME"
- Loads full `SudokuGameState` from PersistenceService

```swift
struct SudokuGameState: Codable {
    let puzzle: SudokuPuzzle
    let elapsedSeconds: Int
    let mistakeCount: Int
    let hintsRemaining: Int
    let undoStack: [BoardSnapshot]
}
```

---

### Files for PR-07

| File | Action |
|------|--------|
| `Games/Sudoku/Views/SudokuWinView.swift` | Create |
| `Games/Sudoku/Views/SudokuPauseOverlayView.swift` | Create |
| `Games/Sudoku/Views/SudokuLoseView.swift` | Create |
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Extend (timer, lifecycle) |
| `Games/Sudoku/Models/SudokuGameState.swift` | Create |

### Acceptance Criteria PR-07
- [ ] Timer counts up correctly, pauses when app backgrounds
- [ ] Win screen appears on puzzle completion with correct time/stars
- [ ] Lose state triggers at 3 mistakes
- [ ] Pause overlay hides board
- [ ] Game state saved and restored across app kill/relaunch
- [ ] Restart reloads same puzzle from scratch

---

## Dependencies

- PR-05 depends on: PR-04 (engine), PR-02 (services)
- PR-06 depends on: PR-05
- PR-07 depends on: PR-06
