# Phase 02 — Persistent Bottom Banner Ad

**Priority:** P1 | **Effort:** 3h | **PR:** PR-12 | **Depends on:** PR-11

---

## Context Links
- [AdsService.swift](../../SmartGames/SharedServices/Ads/AdsService.swift)
- [MonetizationConfig](phase-01-monetization-config-model.md) -- `bannerEnabled`
- [SudokuGameView](../../SmartGames/Games/Sudoku/Views/SudokuGameView.swift)

---

## Overview

Add a persistent bottom banner ad to the Sudoku game screen using `GADBannerView` wrapped in a SwiftUI `UIViewRepresentable`. The banner stays visible during gameplay, respects safe area, and does not interfere with the board, toolbar, or number pad layout.

---

## BannerAdCoordinator

```swift
// SharedServices/Ads/BannerAdCoordinator.swift

import GoogleMobileAds
import UIKit
import Combine

/// Manages a single GADBannerView lifecycle.
@MainActor
final class BannerAdCoordinator: NSObject, ObservableObject {
    @Published var bannerHeight: CGFloat = 0
    @Published var isBannerLoaded: Bool = false

    private var bannerView: GADBannerView?
    private let adUnitID: String
    private let refreshInterval: Int // seconds, 0 = SDK default

    init(adUnitID: String = AdsConfig.bannerAdUnitID, refreshInterval: Int = 60) {
        self.adUnitID = adUnitID
        self.refreshInterval = refreshInterval
        super.init()
    }

    /// Creates and loads the banner. Call once when the hosting view appears.
    func loadBanner(width: CGFloat, rootViewController: UIViewController) -> GADBannerView {
        let adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        let banner = GADBannerView(adSize: adaptiveSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = rootViewController
        banner.delegate = self
        banner.load(GADRequest())
        bannerView = banner
        return banner
    }
}

extension BannerAdCoordinator: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        isBannerLoaded = true
        bannerHeight = bannerView.adSize.size.height
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        isBannerLoaded = false
        bannerHeight = 0
        // Analytics logged in Phase 6
    }
}
```

**Refresh interval:** SDK-controlled. No app-side configuration needed.

---

## BannerAdView (SwiftUI Wrapper)

```swift
// SharedServices/Ads/BannerAdView.swift

import SwiftUI
import GoogleMobileAds

/// SwiftUI wrapper for GADBannerView. Fixed at bottom of screen.
struct BannerAdView: UIViewRepresentable {
    let coordinator: BannerAdCoordinator

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        // Banner will be added when root VC is available
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard uiView.subviews.isEmpty else { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let width = uiView.frame.width > 0 ? uiView.frame.width : UIScreen.main.bounds.width
        let banner = coordinator.loadBanner(width: width, rootViewController: rootVC)
        banner.translatesAutoresizingMaskIntoConstraints = false
        uiView.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: uiView.centerXAnchor),
            banner.bottomAnchor.constraint(equalTo: uiView.bottomAnchor)
        ])
    }
}
```

---

## Integration into SudokuGameView

Layout order (top to bottom):
1. Stats bar (mistakes, difficulty, timer)
2. Board (flexible, fills available space)
3. Toolbar (undo, eraser, pencil, hint)
4. Number pad (1-9)
5. **Banner ad (fixed height, safe area bottom)**

```swift
// In SudokuGameView body
VStack(spacing: 0) {
    // existing content...
    statsBar
    boardView
    toolbarView
    numberPadView

    // Banner ad -- only when enabled and not removed via IAP
    if !storeService.isAdsRemoved && config.bannerEnabled {
        BannerAdView(coordinator: bannerCoordinator)
            .frame(height: bannerCoordinator.bannerHeight)
            .animation(.easeInOut(duration: 0.3), value: bannerCoordinator.isBannerLoaded)
    }
}
.ignoresSafeArea(.keyboard) // banner stays when keyboard not relevant
```

**Layout safety:**
- Banner height is adaptive (50pt on iPhone, 90pt on iPad via `GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth`)
- Board sizing subtracts banner height from available space
- When banner fails to load, `bannerHeight = 0` -> no space reserved -> board expands
- When `isAdsRemoved`, banner view is removed entirely (no empty space)

---

## AdsService Changes

Add `BannerAdCoordinator` as a lazy property -- created per-game, not globally:

```swift
// AdsService.swift
/// Creates a banner coordinator configured for the given game's monetization settings.
func makeBannerCoordinator(config: MonetizationConfig) -> BannerAdCoordinator {
    BannerAdCoordinator(adUnitID: AdsConfig.bannerAdUnitID)
}
```

The coordinator is owned by the game view, not AdsService -- it lives only while the game screen is active.

---

## Files to Create

| File | Purpose |
|------|---------|
| `SharedServices/Ads/BannerAdCoordinator.swift` | GADBannerView lifecycle + delegate |
| `SharedServices/Ads/BannerAdView.swift` | UIViewRepresentable wrapper |

## Files to Modify

| File | Change |
|------|--------|
| `SharedServices/Ads/AdsService.swift` | Add `makeBannerCoordinator(config:)` factory |
| `SharedServices/Ads/AdsConfig.swift` | Add `bannerAdUnitID` (already in Phase 01) |
| `Games/Sudoku/Views/SudokuGameView.swift` | Add `BannerAdView` at bottom of VStack; create coordinator on appear |

---

## Ad Load Failure Fallback UX

- Banner fails to load -> `bannerHeight = 0` -> UI collapses gracefully, board uses full space
- No error message shown to user (silent fallback)
- Analytics event `ad_banner_load_failed` logged (Phase 06)
- Retry happens automatically via GADBannerView SDK (next refresh cycle)

---

## Acceptance Criteria

- [ ] Banner ad visible at bottom of Sudoku game screen (test ID in simulator)
- [ ] Banner does not overlap board, toolbar, or number pad
- [ ] Board resizes correctly when banner loads/fails
- [ ] Banner hidden when `isAdsRemoved == true`
- [ ] Banner respects safe area on notched devices
- [ ] Banner auto-refreshes (SDK-controlled)
- [ ] Landscape: not applicable (app is portrait-locked)

## Tests

- Manual: banner loads with test ad ID on simulator
- Manual: layout integrity on iPhone SE (smallest), iPhone 15 Pro Max, iPad
- Manual: banner disappears after purchasing Remove Ads
- Unit: `BannerAdCoordinator` state transitions (loaded/failed -> height updates)
