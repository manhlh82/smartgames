# Phase 04 — Lobby + Win + Pause + Clue List Views

## Context Links
- [plan.md](plan.md) — overview
- [phase-03](phase-03-core-views.md) — game views this connects to
- Pattern ref: `SmartGames/Games/Sudoku/Views/SudokuLobbyView.swift`, `SudokuWinView.swift`

## Overview
- **Priority:** P2
- **Status:** pending
- Build lobby (difficulty selection), win overlay, pause overlay, and full clue list view.

## Requirements

### CrosswordLobbyView
- Difficulty cards: Mini (5x5) and Standard (9x9) with play buttons
- Daily Challenge section (placeholder — wired in Phase 5)
- Banner ad at bottom
- Show current hint count
- Resume button if active game exists (check persistence key)
- Follow `SudokuLobbyView` layout pattern

### CrosswordWinView
- Displayed when gamePhase == .won
- Show: completion time, hints used, gold earned, hints granted
- Star rating: 3 stars (0 hints, <3min), 2 stars (<5 hints, <10min), 1 star (else)
- Buttons: "New Puzzle", "Back to Lobby"
- Celebration animation (confetti or similar)

### CrosswordPauseOverlay
- Displayed when gamePhase == .paused
- Buttons: Resume, Restart, Quit (back to lobby)
- Blurred background hiding the grid (prevent cheating)
- Follow `SudokuPauseOverlayView` pattern

### CrosswordClueListView
- Full scrollable list of all clues grouped by Across / Down
- Tapping a clue selects that word on the grid + dismisses list
- Show completion indicator (checkmark) for fully filled clues
- Presented as sheet from clue bar tap or toolbar button

## Related Code Files
- **Create:** `SmartGames/Games/Crossword/Views/CrosswordLobbyView.swift`
- **Create:** `SmartGames/Games/Crossword/Views/CrosswordWinView.swift`
- **Create:** `SmartGames/Games/Crossword/Views/CrosswordPauseOverlay.swift`
- **Create:** `SmartGames/Games/Crossword/Views/CrosswordClueListView.swift`

## Implementation Steps
1. Create `CrosswordLobbyView.swift` — difficulty cards, play buttons, resume check
2. Create `CrosswordWinView.swift` — stats display, star rating, gold/hint rewards
3. Create `CrosswordPauseOverlay.swift` — blur + resume/restart/quit
4. Create `CrosswordClueListView.swift` — grouped clue list with tap-to-select
5. Wire clue list sheet presentation into CrosswordGameView
6. Compile check

## Todo List
- [ ] CrosswordLobbyView with difficulty selection
- [ ] CrosswordWinView with stats + rewards
- [ ] CrosswordPauseOverlay with blur
- [ ] CrosswordClueListView with grouped clues
- [ ] Wire clue list into game view
- [ ] Compile check

## Success Criteria
- Lobby shows both difficulties with correct labels
- Resume button appears only when saved game exists
- Win overlay shows correct stats and rewards
- Pause overlay hides grid content
- Clue list groups correctly and tap navigates to word
- All views under 200 lines
