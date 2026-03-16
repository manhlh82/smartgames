# Phase 03 — Post-Level Interstitial (Revised)

**Priority:** P1 | **Effort:** 2h | **PR:** PR-13 | **Depends on:** PR-11

---

## Context Links
- [InterstitialAdCoordinator.swift](../../SmartGames/SharedServices/Ads/InterstitialAdCoordinator.swift) -- current impl
- [SudokuGameViewModel.swift](../../SmartGames/Games/Sudoku/ViewModels/SudokuGameViewModel.swift) -- `checkWin()`
- [MonetizationConfig](phase-01-monetization-config-model.md) -- `interstitialFrequency`

---

## Overview

Revise interstitial behavior: show after every N completed Sudoku levels (default N=1, configurable). Remove old "max 1 per session" limit. The interstitial appears after the win screen is dismissed, before returning to lobby/hub.

---

## Current State vs Target

| Aspect | Current | Target |
|--------|---------|--------|
| Trigger | After win, before hub | After win screen dismissed |
| Frequency | Max 1 per session | Every N completed levels (default 1) |
| Duration | SDK-controlled | SDK-controlled — ignored |
| Skippable | N/A (alert stub) | SDK-controlled — ignored |
| Rate limit | `showCount < 1` | Based on `interstitialFrequency` from config |
| IAP gate | `storeService.hasRemovedAds` | Same (unchanged) |

**Ad timing:** Duration and skippability are SDK/AdMob-controlled. Ignored from app perspective.

---

## InterstitialAdCoordinator Changes

```swift
// InterstitialAdCoordinator.swift — revised

@MainActor
final class InterstitialAdCoordinator: NSObject, ObservableObject {
    @Published var isAdReady: Bool = false
    private var completedLevelCount: Int = 0
    private var interstitialFrequency: Int = 1

    /// Configure frequency from MonetizationConfig. Call once when game module loads.
    func configure(frequency: Int) {
        self.interstitialFrequency = max(1, frequency)
    }

    /// Call after every level completion. Returns true if interstitial should be shown.
    func shouldShowAfterLevelComplete() -> Bool {
        completedLevelCount += 1
        return isAdReady && (completedLevelCount % interstitialFrequency == 0)
    }

    /// Reset level counter (e.g., on new session or game module change)
    func resetLevelCounter() {
        completedLevelCount = 0
    }

    func loadAd() async { ... } // unchanged
    func showIfReady(from vc: UIViewController) { ... } // remove old canShowAd guard, just check isAdReady
}
```

Remove: `showCount`, `lastShowTime`, `canShowAd`, `maxInterstitialsPerSession`, `interstitialCooldownSeconds`.

---

## Flow: Win -> Interstitial -> Navigation

```
Player completes level
  -> gamePhase = .won
  -> Win screen appears (stats, stars, buttons)
  -> User taps "Next Puzzle" or "Back to Menu"
  -> ViewModel calls: interstitial.shouldShowAfterLevelComplete()
     -> If true AND !isAdsRemoved:
        -> Show interstitial (full-screen, SDK-controlled)
        -> On dismiss: navigate to next screen
     -> If false OR isAdsRemoved:
        -> Navigate immediately
```

**Implementation in ViewModel:**

```swift
// SudokuGameViewModel — new method
func handlePostWinNavigation(action: PostWinAction) {
    let config = monetizationConfig // from injected MonetizationConfig
    let shouldShow = config.interstitialEnabled
        && ads.interstitial.shouldShowAfterLevelComplete()
        && storeService?.hasRemovedAds != true

    if shouldShow {
        ads.showInterstitialIfReady()
        // InterstitialAdCoordinator dismiss callback triggers navigation
    }
    // Navigation proceeds (interstitial is non-blocking if ad fails)
}

enum PostWinAction {
    case nextPuzzle
    case backToMenu
}
```

**Key UX decision:** Interstitial is non-blocking. If the ad fails to load or isn't ready, navigation happens immediately. User is never stuck waiting for an ad.

---

## Skippability

- Controlled by AdMob ad creative, not app code
- Video interstitials: skip button appears after ~5s (standard AdMob behavior)
- Static interstitials: close button appears immediately
- App cannot override skip timing

---

## Files to Modify

| File | Change |
|------|--------|
| `SharedServices/Ads/InterstitialAdCoordinator.swift` | Replace session cap with level-frequency logic |
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Add `handlePostWinNavigation()`, pass config |
| `Games/Sudoku/Views/SudokuWinView.swift` | Wire "Next Puzzle" / "Back" through post-win handler |

---

## Acceptance Criteria

- [ ] Interstitial fires after every N completed levels (N=1 default)
- [ ] Level counter increments on each win
- [ ] Interstitial skipped when `isAdsRemoved`
- [ ] Navigation proceeds immediately if ad not ready (non-blocking)
- [ ] No interstitial on game-over/lose (only on win)
- [ ] Old session cap removed

## Tests

- Unit: `shouldShowAfterLevelComplete()` returns true on correct intervals
- Unit: frequency=3 means interstitial on levels 3, 6, 9...
- Unit: returns false when `isAdReady == false`
- Manual: interstitial appears between levels in simulator
