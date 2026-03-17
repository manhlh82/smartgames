# Phase 07 — Polish + Testing

## Context Links
- [plan.md](plan.md) — overview
- All previous phases

## Overview
- **Priority:** P2
- **Status:** pending
- Final pass: compile verification, UI polish, edge case handling, analytics audit.

## Requirements

### Compile Verification
- Clean build with zero warnings related to Crossword files
- All Crossword files under 200-line limit

### UI Polish
- Grid cell sizing looks good on iPhone SE through Pro Max
- Black cells have proper contrast
- Selected word highlight visible but not overpowering
- Clue bar text truncation with ellipsis for long clues
- Keyboard does not obscure grid (scroll or resize)
- Smooth direction toggle animation
- Win overlay celebration feels rewarding

### Edge Cases
- Empty puzzle bank for a difficulty → graceful fallback message
- Rotate device mid-game → layout adapts
- Background/foreground → timer pauses/resumes, auto-save triggers
- All cells revealed via hints → still triggers win
- Daily challenge already completed → show result, disable play

### Analytics Audit
- Verify all 6 crossword analytics events fire at correct moments
- Check event parameters match expected format
- Daily challenge events use shared `daily_challenge_*` pattern

### Persistence Verification
- Kill app mid-game → relaunch → game restores correctly
- Complete game → persistence key cleared
- Hint balance persists across sessions

### Monetization Verification
- Banner ad shows in lobby and game view
- Interstitial fires after every 2nd puzzle completion
- Rewarded ad flow works when hints exhausted
- Diamond reveal letter deducts correctly

## Implementation Steps
1. Run full compile: `xcodegen generate && xcodebuild -scheme SmartGames -destination 'platform=iOS Simulator,name=iPhone 16' build`
2. Fix any compile errors or warnings
3. Check all files are under 200 lines — split if needed
4. Manual UI test on simulator: both puzzle sizes, all hint types, undo, daily challenge
5. Verify analytics events in console log
6. Test save/restore cycle
7. Test monetization flows
8. Code review pass — check for YAGNI/KISS/DRY violations

## Todo List
- [ ] Clean compile with zero Crossword warnings
- [ ] All files under 200 lines
- [ ] UI looks correct on multiple screen sizes
- [ ] Keyboard input works reliably
- [ ] Direction toggle works correctly
- [ ] All hint types function properly
- [ ] Undo restores state correctly
- [ ] Daily challenge deterministic + streak works
- [ ] Save/restore cycle verified
- [ ] Analytics events fire correctly
- [ ] Banner + interstitial + rewarded ads work
- [ ] Diamond hint deduction works
- [ ] Code review pass

## Success Criteria
- Zero compile errors/warnings
- All gameplay flows work end-to-end
- Monetization integrated and functional
- Analytics events verified
- Persistence works across app lifecycle
- UI polished and responsive across device sizes
