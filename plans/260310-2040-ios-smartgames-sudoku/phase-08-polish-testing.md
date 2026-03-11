# Phase 08 — Polish, Testing & App Store Prep

**Priority:** High | **Effort:** M | **PR:** PR-10

---

## Overview

Final hardening before App Store submission: accessibility, edge case fixes, performance pass, App Store metadata, and TestFlight distribution.

---

## PR-10 Goal

Production-ready build: all tests green, accessibility labels, App Store screenshots + metadata, privacy manifest, TestFlight build.

---

## 0. Unit Test Spec — Cell Interaction Rules

These tests MUST exist in `SudokuGameViewModelTests.swift` to verify the interaction contract.

### selectCell — pre-filled cell

```swift
// Tapping a given cell: highlight states correct, keypad guard active
func test_selectGivenCell_highlightsSameDigitAndPeers() {
    // given cell at (0,0) has value 5
    sut.selectCell(row: 0, col: 0)
    // selected cell → .selected (not .selectedEmpty)
    XCTAssertEqual(sut.highlightState(for: 0, col: 0), .selected)
    // all other cells with value 5 → .sameNumber
    // all row/col/box peers → .related (or .sameNumber if they also share digit)
}

func test_placeNumber_onGivenCell_isNoOp() {
    sut.selectCell(row: 0, col: 0)  // given cell
    let before = sut.puzzle.board[0][0].value
    sut.placeNumber(9)
    XCTAssertEqual(sut.puzzle.board[0][0].value, before)  // unchanged
}
```

### selectCell — empty editable cell

```swift
func test_selectEmptyCell_highlightState_isSelectedEmpty() {
    // find an empty cell
    sut.selectCell(row: emptyRow, col: emptyCol)
    XCTAssertEqual(sut.highlightState(for: emptyRow, col: emptyCol), .selectedEmpty)
}

func test_selectEmptyCell_peersAreRelated_notSameNumber() {
    sut.selectCell(row: emptyRow, col: emptyCol)
    // peers must be .related; cannot be .sameNumber (cell has no value)
    for peer in peers(emptyRow, emptyCol) {
        XCTAssertEqual(sut.highlightState(for: peer.row, col: peer.col), .related)
    }
}

func test_placeNumber_onEmptyEditableCell_placesValue() {
    sut.selectCell(row: emptyRow, col: emptyCol)
    let correctDigit = sut.puzzle.solution[emptyRow][emptyCol]
    sut.placeNumber(correctDigit)
    XCTAssertEqual(sut.puzzle.board[emptyRow][emptyCol].value, correctDigit)
}
```

### placeNumber — no selection guard

```swift
func test_placeNumber_withNoSelection_isNoOp() {
    sut.selectedCell = nil
    let boardBefore = sut.puzzle.board
    sut.placeNumber(5)
    XCTAssertEqual(sut.puzzle.board, boardBefore)  // board unchanged
}
```

### highlightState — priority ordering

```swift
func test_highlightPriority_errorBeforeRelated() {
    // place wrong digit in a peer cell → error takes priority over .related
}

func test_highlightPriority_selectedBeforeSameNumber() {
    // selected cell always returns .selected/.selectedEmpty, never .sameNumber
}
```

---

## 1. Accessibility

| Element | Requirement |
|---------|-------------|
| SudokuCellView | `accessibilityLabel("Row \(row+1), Column \(col+1), \(value ?? "empty")")` |
| SudokuCellView given | `accessibilityHint("Given clue, cannot be changed")` |
| Number pad buttons | `accessibilityLabel("\(number)")` |
| Tool buttons | `accessibilityLabel("Undo")` etc. |
| Timer | `accessibilityLabel("Elapsed time \(formattedTime)")` |
| Mistake counter | `accessibilityLabel("Mistakes: \(count) of 3")` |

- Dynamic Type: all text scales correctly
- VoiceOver: full board navigation order (row by row, left to right)
- Minimum tap target: 44×44pt for all interactive elements

---

## 2. Performance Checklist

- [ ] Board renders at 60fps on iPhone 12 (no dropped frames during highlight transitions)
- [ ] Puzzle load time < 200ms (from JSON bank)
- [ ] Auto-save debounced, never blocks main thread
- [ ] Puzzle generation (on-device fallback) done on background Task, never freezes UI
- [ ] Memory: no retain cycles in ViewModels (use `[weak self]` in closures, `weak var` delegates)

Profiling tools: Instruments → Time Profiler + Allocations.

---

## 3. Edge Cases to Verify

| Scenario | Expected Behavior |
|----------|------------------|
| App killed mid-game | Resume from exact state on relaunch |
| App backgrounded during rewarded ad | Ad dismissed gracefully, reward still granted |
| No ad loaded when hint tapped | Show "Ad not available, try again later" |
| All puzzles in bank exhausted | Seamlessly generate on-device, no blank screen |
| Puzzle bank JSON malformed | Fallback to on-device generation, log error |
| 3 mistakes on final cell | Lose state shown, not win state |
| Board completed with pencil marks remaining | Win state still triggers correctly |
| Undo past game start (empty stack) | Undo button disabled/greyed |
| Device rotation | Layout stable (lock to portrait via Info.plist) |
| iOS 16 vs iOS 17 | Test both — no SwiftData APIs used without fallback |
| Tap pre-filled cell, then tap keypad | Cell value unchanged; no crash |
| Tap keypad with nothing selected | No state change; no crash |
| Tap pre-filled cell | Same-digit cells highlighted (`.sameNumber`); row/col/box highlighted (`.related`); selected cell is deep blue (`.selected`) |
| Tap empty editable cell | Selected cell is yellow (`.selectedEmpty`); row/col/box highlighted (`.related`); no same-number highlight |
| Re-tap same cell | Keeps selection; highlight states unchanged |

---

## 4. Privacy Manifest

Apple requires `PrivacyInfo.xcprivacy` from iOS 17.4+ SDK. Required for AdMob and Firebase SDKs.

```xml
<!-- PrivacyInfo.xcprivacy -->
<key>NSPrivacyTracking</key>
<true/>
<key>NSPrivacyTrackingDomains</key>
<array>
  <!-- AdMob tracking domains -->
</array>
<key>NSPrivacyCollectedDataTypes</key>
<array>
  <dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeDeviceID</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <false/>
    <key>NSPrivacyCollectedDataTypeTracking</key>
    <true/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array>
      <string>NSPrivacyCollectedDataTypePurposeThirdPartyAdvertising</string>
    </array>
  </dict>
</array>
```

---

## 5. App Store Metadata

**Required assets:**
- App icon: 1024×1024 PNG (no alpha)
- Screenshots: 6.7" (iPhone 15 Pro Max), 5.5" (iPhone 8 Plus) — minimum 2 per size
- Preview video: optional but recommended for games

**Screenshots to capture:**
1. Hub screen (shows multi-game promise)
2. Sudoku lobby with difficulty selection
3. Active gameplay (highlighted cell, number pad visible)
4. Win screen (3 stars)

**App Store description (draft):**
```
SmartGames — Brain Training Puzzles

Sharpen your mind with classic puzzle games.

• Sudoku — 4 difficulty levels, unlimited puzzles
• Undo, hints, pencil mode
• Track your progress and beat your best time

More games coming soon.
```

**Keywords:** sudoku, puzzle, brain, logic, number, game, daily

**Age rating:** 4+ (no objectionable content)

**Categories:** Primary — Games › Puzzle; Secondary — Education

---

## 6. TestFlight Setup

- Build scheme: `Release` with `DEBUG_ADS=false`
- Internal testers: dev team
- External testers: 10–20 beta users via TestFlight public link
- Feedback to collect:
  - Difficulty calibration (Easy too easy? Hard too hard?)
  - Hint prompt UX (annoying or acceptable?)
  - Any crashes (via Firebase Crashlytics)

Add **Firebase Crashlytics** in this phase:
```swift
// Package.swift
.package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
// Add: FirebaseCrashlytics target
```

---

## 7. CI/CD Final Setup

```yaml
# .github/workflows/release.yml
name: Release Build
on:
  push:
    tags: ['v*']
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Setup signing
        env:
          CERTIFICATE_BASE64: ${{ secrets.CERTIFICATE_BASE64 }}
          PROVISIONING_PROFILE_BASE64: ${{ secrets.PROVISIONING_PROFILE_BASE64 }}
        run: scripts/setup-signing.sh
      - name: Inject secrets
        env:
          ADS_REWARDED_ID: ${{ secrets.ADS_REWARDED_ID }}
          ADS_INTERSTITIAL_ID: ${{ secrets.ADS_INTERSTITIAL_ID }}
          GOOGLE_SERVICE_INFO: ${{ secrets.GOOGLE_SERVICE_INFO }}
        run: scripts/inject-secrets.sh
      - name: Build & Archive
        run: xcodebuild archive ...
      - name: Upload to TestFlight
        run: xcrun altool --upload-app ...
```

---

## 8. Final Test Checklist

### Unit Tests (must all pass)
- [ ] `SudokuGeneratorTests` — all 4 difficulties
- [ ] `SudokuSolverTests` — solve + uniqueness
- [ ] `SudokuValidatorTests` — valid/invalid placements
- [ ] `PersistenceServiceTests` — save/load round-trip
- [ ] `SettingsServiceTests` — persistence
- [ ] `AnalyticsServiceTests` — event firing
- [ ] `AdsServiceTests` — mock reward callback

### Manual Test Scenarios
- [ ] Full game flow: hub → lobby → Easy game → win → interstitial → hub
- [ ] Hint flow: use 3 hints → ad prompt → watch ad → 3 more hints
- [ ] Lose flow: 3 mistakes → lose screen → watch ad → continue
- [ ] Resume flow: background app → relaunch → resume game intact
- [ ] Settings: toggle sound/haptics, verify they persist
- [ ] All 4 difficulty levels: start and play briefly
- [ ] Fresh install: ATT prompt shown, no crash

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `PrivacyInfo.xcprivacy` | Create |
| `.github/workflows/release.yml` | Create |
| `scripts/setup-signing.sh` | Create |
| `scripts/inject-secrets.sh` | Create |
| All View files | Add accessibility labels |
| `Package.swift` | Add FirebaseCrashlytics |

---

## Acceptance Criteria

- [ ] Zero compiler warnings in Release build
- [ ] All unit tests pass on CI
- [ ] VoiceOver navigates full board correctly
- [ ] App passes App Store Connect automated checks (no missing privacy keys)
- [ ] TestFlight build installable and playable end-to-end
- [ ] Crash rate < 0.1% on TestFlight (Firebase Crashlytics)

---

## Dependencies

- All previous PRs (01–09) merged and green
