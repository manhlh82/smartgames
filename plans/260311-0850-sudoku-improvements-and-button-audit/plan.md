---
title: "Sudoku Improvements & Button Audit"
description: "Systematic audit of all interactive elements + UX polish + new features"
status: completed
priority: P2
effort: 8h
branch: main
tags: [sudoku, ux, audit, polish]
created: 2026-03-11
---

# Sudoku Improvements & Button Audit

## Context
Sudoku gameplay is functionally complete (10 PRs shipped). This plan audits every interactive element for correctness and adds polish for a production-quality game.

## Phase Summary

| Phase | File | Status | Effort |
|-------|------|--------|--------|
| 1 - Button Audit & Fixes | `phase-01-button-audit-and-fixes.md` | completed | 3h |
| 2 - UX Improvements | `phase-02-ux-improvements.md` | completed | 3h |
| 3 - New Features | `phase-03-new-features.md` | completed | 2h |

## Audit Summary (Key Findings)

### Working Correctly
- Number pad 1-9: placement, pencil toggle, error detection, completed-number dimming
- Undo: snapshot/restore with mistake count rollback, 50-depth cap
- Erase: clears value + pencil marks + error flag on non-given cells
- Pencil mode: toggle works, auto-clears marks on peer placement
- Hint: reveals cell, decrements counter, ad flow for 0 hints, IAP grant
- Pause/Resume: timer stop/start, board hidden via overlay, scenePhase auto-pause
- Win/Lose: state machine transitions, stats recording, Game Center submission
- Auto-save: debounced 500ms, saves on pause, scene background

### Issues Found (Bugs/Gaps)

1. **Back button does NOT auto-save** -- `router.pop()` called directly without `viewModel.autoSave()` first
2. **"Watch Ad to Continue" on lost screen resumes without restarting timer** -- calls `viewModel.resume()` but game may not be in `.paused` state (it's in `.lost`), so `startTimer()` never fires
3. **Restart from pause doesn't dismiss pause first** -- `viewModel.restart()` sets `.playing` but pause overlay checks `gamePhase == .paused`, so this works but timer starts twice (old timer not explicitly cancelled before `startTimer()`)
4. **Erase button has no disabled state** -- always clickable even when no cell selected or cell is given (guard returns silently, no visual feedback)
5. **No pencil-mode snapshot** -- pencil mark changes don't push to undo stack (intentional or bug?)
6. **Star rating logic has OR instead of AND** -- 2-star condition `mistakeCount <= 1 || elapsedSeconds < 600` means fast games with many mistakes get 2 stars

## Key Dependencies
- No external SDK changes required
- All fixes are within existing Sudoku module files
