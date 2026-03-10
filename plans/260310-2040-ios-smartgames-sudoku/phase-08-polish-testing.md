# Phase 08 — Polish, Testing & App Store Prep

**Priority:** High | **Effort:** M | **PR:** PR-10

---

## Overview

Final hardening before App Store submission: accessibility, edge case fixes, performance pass, App Store metadata, and TestFlight distribution.

---

## PR-10 Goal

Production-ready build: all tests green, accessibility labels, App Store screenshots + metadata, privacy manifest, TestFlight build.

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
