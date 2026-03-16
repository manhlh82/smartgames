# Phase 06 — Analytics & UX Polish

**Priority:** P1 | **Effort:** 5h | **PR:** PR-16 | **Depends on:** PR-12, PR-13, PR-14, PR-15

---

## Context Links
- [AnalyticsEvent+Ads.swift](../../SmartGames/SharedServices/Analytics/AnalyticsEvent+Ads.swift) -- existing ad events
- [AnalyticsEvent+Sudoku.swift](../../SmartGames/SharedServices/Analytics/AnalyticsEvent+Sudoku.swift) -- existing gameplay events
- All phase files in this plan

---

## Overview

Add all missing analytics events for banner ads, revised hint system, mistake reset, and ad UX fallbacks. Polish UX for ad failure scenarios, hint count display, and reward feedback.

---

## New Analytics Events

### Banner Ad Events

```swift
// AnalyticsEvent+Ads.swift — add

static func adBannerLoaded(gameId: String) -> AnalyticsEvent {
    AnalyticsEvent("ad_banner_loaded", ["game_id": gameId])
}

static func adBannerLoadFailed(gameId: String, errorCode: Int) -> AnalyticsEvent {
    AnalyticsEvent("ad_banner_load_failed", [
        "game_id": gameId,
        "error_code": errorCode
    ])
}

static func adBannerClicked(gameId: String) -> AnalyticsEvent {
    AnalyticsEvent("ad_banner_clicked", ["game_id": gameId])
}

static func adBannerImpression(gameId: String) -> AnalyticsEvent {
    AnalyticsEvent("ad_banner_impression", ["game_id": gameId])
}
```

### Hint Events (Revised)

```swift
// AnalyticsEvent+Sudoku.swift — add

static func hintEarnedFromAd(difficulty: String, hintsAfter: Int) -> AnalyticsEvent {
    AnalyticsEvent("hint_earned_from_ad", [
        "difficulty": difficulty,
        "hints_after": hintsAfter
    ])
}

static func hintEarnedFromLevel(difficulty: String, hintsAfter: Int) -> AnalyticsEvent {
    AnalyticsEvent("hint_earned_from_level", [
        "difficulty": difficulty,
        "hints_after": hintsAfter
    ])
}

static func hintEarnedFromIAP(hintsAfter: Int) -> AnalyticsEvent {
    AnalyticsEvent("hint_earned_from_iap", ["hints_after": hintsAfter])
}

static func hintCapReached(currentHints: Int, maxCap: Int) -> AnalyticsEvent {
    AnalyticsEvent("hint_cap_reached", [
        "current_hints": currentHints,
        "max_cap": maxCap
    ])
}
```

### Mistake Reset Events

```swift
// AnalyticsEvent+Ads.swift — add

static func mistakeResetPromptShown(difficulty: String, mistakeCount: Int) -> AnalyticsEvent {
    AnalyticsEvent("mistake_reset_prompt_shown", [
        "difficulty": difficulty,
        "mistake_count": mistakeCount
    ])
}

static func mistakeResetUsed(difficulty: String, usesThisLevel: Int) -> AnalyticsEvent {
    AnalyticsEvent("mistake_reset_used", [
        "difficulty": difficulty,
        "uses_this_level": usesThisLevel
    ])
}

static func mistakeResetDeclined(difficulty: String) -> AnalyticsEvent {
    AnalyticsEvent("mistake_reset_declined", ["difficulty": difficulty])
}
```

### Ad Unavailable

```swift
static func adUnavailable(adType: String, reason: String, context: String) -> AnalyticsEvent {
    AnalyticsEvent("ad_unavailable", [
        "ad_type": adType,       // "rewarded", "interstitial", "banner"
        "reason": reason,        // "not_loaded", "load_failed", "network"
        "context": context       // "hints", "mistake_reset", "continue", "post_level"
    ])
}
```

### Post-Level Interstitial (Expanded)

```swift
// Already exists: adInterstitialShown, adInterstitialDismissed
// Add:
static func adInterstitialSkipped(reason: String) -> AnalyticsEvent {
    AnalyticsEvent("ad_interstitial_skipped", ["reason": reason])
    // reason: "not_ready", "ads_removed", "frequency_not_met"
}
```

---

## Complete Event Catalog

| Event | Trigger | Parameters |
|-------|---------|------------|
| `ad_banner_loaded` | GADBannerView receives ad | `game_id` |
| `ad_banner_load_failed` | GADBannerView fails | `game_id`, `error_code` |
| `ad_banner_clicked` | User taps banner | `game_id` |
| `ad_banner_impression` | Banner becomes visible | `game_id` |
| `ad_interstitial_skipped` | Interstitial not shown | `reason` |
| `hint_earned_from_ad` | Rewarded ad completes for hints | `difficulty`, `hints_after` |
| `hint_earned_from_level` | Level completed, hint granted | `difficulty`, `hints_after` |
| `hint_earned_from_iap` | Hint pack purchased | `hints_after` |
| `hint_cap_reached` | Grant attempted at cap | `current_hints`, `max_cap` |
| `mistake_reset_prompt_shown` | User taps reset button | `difficulty`, `mistake_count` |
| `mistake_reset_used` | Ad completed, mistakes reset | `difficulty`, `uses_this_level` |
| `mistake_reset_declined` | User cancels reset prompt | `difficulty` |
| `ad_unavailable` | Any ad not available when requested | `ad_type`, `reason`, `context` |

---

## UX Polish

### 1. Ad Load Failure Fallback

When user taps "Watch Ad" (for hints or mistake reset) but no ad is loaded:

```swift
// In SudokuGameView, hint/mistake-reset ad prompt
if !adsService.isRewardedAdReady {
    // Show "No ad available right now. Try again in a moment."
    // Auto-dismiss after 3s, return to .playing
    // Log ad_unavailable event
}
```

Do NOT show a blank screen or leave user stuck. Always provide a fallback path.

### 2. Hint Count Display

Already shown as badge on hint toolbar button. Ensure:
- Badge updates immediately on all grant paths (ad, level, IAP)
- Badge shows "0" distinctly (e.g., red tint) when exhausted
- After level complete, if hint granted, brief pulse animation on badge

### 3. Reward Feedback

After rewarded ad completes:
- **Hints:** Toast banner: "+3 Hints" (or actual amount granted if capped)
- **Mistake reset:** Mistake counter animates from N -> 0 with color transition
- **Level complete hint:** Subtle badge pulse (no intrusive popup)

### 4. Timing: No Disruptive Ads

| Moment | Ad Allowed? |
|--------|------------|
| During active cell input | No (never) |
| During timer counting | Banner only (passive) |
| After win, user taps navigation | Interstitial (expected transition) |
| User explicitly taps "Watch Ad" | Rewarded (user-initiated) |
| On app launch | Never (no pre-roll) |
| On returning from background | Never |

### 5. Banner During Pause

- Banner remains visible during pause overlay (passive, non-intrusive)
- Banner hidden during win/lose screens (overlays cover it)

---

## Files to Modify

| File | Change |
|------|--------|
| `SharedServices/Analytics/AnalyticsEvent+Ads.swift` | Add banner, mistake reset, ad_unavailable events |
| `SharedServices/Analytics/AnalyticsEvent+Sudoku.swift` | Add hint_earned_from_*, hint_cap_reached events |
| `SharedServices/Ads/BannerAdCoordinator.swift` | Log banner analytics in delegate methods |
| `Games/Sudoku/Views/SudokuGameView.swift` | Ad failure fallback UI; reward feedback toasts; hint badge polish |
| `Games/Sudoku/ViewModels/SudokuGameViewModel.swift` | Wire analytics into all new grant/reset paths |

---

## Acceptance Criteria

- [ ] All events in catalog fire at correct moments (verified via Firebase DebugView)
- [ ] No PII in any event parameters
- [ ] Ad failure shows user-friendly message, never blank/stuck screen
- [ ] Hint badge updates reactively on all grant paths
- [ ] Reward feedback (toast/animation) visible after ad completion
- [ ] No ads during active gameplay input
- [ ] Banner stays during pause, hidden during overlays

## Tests

- Unit: each new `AnalyticsEvent` factory produces correct name + parameters
- Unit: mock analytics service receives expected events during hint grant, mistake reset, banner load
- Manual: Firebase DebugView shows all events in correct sequence
- Manual: ad failure fallback UX on airplane mode
- Manual: hint badge pulse after level complete
