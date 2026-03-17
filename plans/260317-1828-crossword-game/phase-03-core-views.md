# Phase 03 — Core Views

## Context Links
- [plan.md](plan.md) — overview
- [phase-02](phase-02-viewmodel.md) — ViewModel driving these views
- Pattern ref: `SmartGames/Games/Sudoku/Views/SudokuBoardView.swift`, `SudokuCellView.swift`

## Overview
- **Priority:** P1
- **Status:** pending
- Build the main gameplay screen: grid, cells, clue bar, toolbar, and game view container.

## Key Insights
- Grid must support both 5x5 and 9x9 sizes dynamically
- Cell view: black cells solid dark, white cells with optional clue number (top-left), user letter (center), highlight states (selected word, active cell, check feedback)
- Clue bar: horizontal strip below grid showing active clue text + number
- Toolbar: undo, check letter, reveal letter, reveal word, hint count badge
- iOS native keyboard for letter input (not custom number pad like Sudoku)
- Use hidden TextField as first responder to capture keyboard input

## Requirements

### CrosswordCellView
- Props: cellState, solutionChar, isSelected, isInSelectedWord, checkFeedback (.none/.correct/.incorrect)
- Black cell: solid dark fill, no interaction
- White cell: clue number top-left (small font), user letter centered
- Highlight: selected cell = blue border, selected word cells = light blue bg
- Check feedback: green flash (correct) or red flash (incorrect), 1.5s then clear
- Revealed cells: letter in gray/italic to distinguish from user-entered

### CrosswordGridView
- Renders NxN grid of CrosswordCellView
- Tap gesture per cell → calls VM.selectCell(row:col:)
- Grid lines: thin borders between cells, thicker outer border
- GeometryReader to size cells to available width

### CrosswordClueBarView
- Horizontal bar showing: clue number + direction icon + clue text
- Tap to toggle direction (across↔down)
- Swipe left/right to navigate to prev/next clue in same direction

### CrosswordToolbarView
- Buttons: Undo, Check Letter, Reveal Letter, Reveal Word
- Hint count badge on reveal buttons
- Undo button: always enabled when stack non-empty (free)
- Disabled states when hints = 0 (show ad prompt on tap)
- Diamond reveal button: small diamond icon + "1◆"

### CrosswordGameView
- Container: BannerAdView (top) + CurrencyBarView + Grid + ClueBar + Toolbar
- Hidden TextField capturing keyboard input → routes to VM.inputLetter()
- Handle backspace → VM.deleteLetter()
- Pause button in nav bar
- Overlay: pause, win, hint-ad prompt (reuse GamePhase switch pattern)
- OnAppear: start timer, audio. OnDisappear: stop timer, auto-save.

## Related Code Files
- **Create:** `SmartGames/Games/Crossword/Views/CrosswordCellView.swift`
- **Create:** `SmartGames/Games/Crossword/Views/CrosswordGridView.swift`
- **Create:** `SmartGames/Games/Crossword/Views/CrosswordClueBarView.swift`
- **Create:** `SmartGames/Games/Crossword/Views/CrosswordToolbarView.swift`
- **Create:** `SmartGames/Games/Crossword/Views/CrosswordGameView.swift`

## Implementation Steps
1. Create `CrosswordCellView.swift` — cell rendering with all highlight states
2. Create `CrosswordGridView.swift` — NxN grid using LazyVGrid or manual VStack/HStack
3. Create `CrosswordClueBarView.swift` — active clue display + direction toggle
4. Create `CrosswordToolbarView.swift` — action buttons with hint badges
5. Create `CrosswordGameView.swift` — container with hidden TextField, overlays, ad integration
6. Wire up keyboard input: hidden TextField with `.focused()` modifier, onChange routes chars to VM
7. Handle backspace via `.onKeyPress(.delete)` or UIKeyInput bridging
8. Test grid renders for both 5x5 and 9x9 sizes
9. Compile check

## Todo List
- [ ] CrosswordCellView with highlight states
- [ ] CrosswordGridView (dynamic NxN)
- [ ] CrosswordClueBarView with direction toggle
- [ ] CrosswordToolbarView with hint badges
- [ ] CrosswordGameView container
- [ ] Hidden TextField keyboard input
- [ ] Backspace handling
- [ ] BannerAd + CurrencyBar integration
- [ ] Phase overlay switch (pause/win/hintAd)
- [ ] Compile check

## Success Criteria
- Grid renders correctly for both 5x5 and 9x9
- Tapping a cell selects it with visual feedback
- Tapping selected cell toggles direction
- Keyboard input appears in selected cell
- Cursor advances after input
- Clue bar updates on selection change
- Toolbar buttons reflect hint count and undo availability
- All views under 200 lines each
