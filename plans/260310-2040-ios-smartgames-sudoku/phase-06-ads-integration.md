# Phase 06 — Ads Integration

**Priority:** High | **Effort:** M | **PR:** PR-08

---

## Overview

Replace AdsService stub (PR-02) with real Google AdMob integration. Implement rewarded ads (hints + redo) and light interstitial ads (between levels). AppTrackingTransparency (ATT) prompt required before showing ads.

---

## PR-08 Goal

Working AdMob rewarded + interstitial ads. ATT prompt. Ad state exposed to SwiftUI via `AdsService`. No aggressive ads in v1 — user experience first.

---

## SDK Setup

**Package:** Google Mobile Ads SDK via Swift Package Manager
```
https://github.com/googleads/swift-package-manager-google-mobile-ads
```
Version: latest stable (10.x / 11.x as of 2025).

**Info.plist additions:**
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
<key>NSUserTrackingUsageDescription</key>
<string>We use this to show you more relevant ads and improve your experience.</string>
<key>SKAdNetworkItems</key>
<!-- AdMob SKAdNetwork IDs -->
```

**Initialization in `SmartGamesApp.swift`:**
```swift
GADMobileAds.sharedInstance().start(completionHandler: nil)
```

---

## AppTrackingTransparency (ATT)

ATT prompt shown **once** on first launch, **after** app has been open ~2 seconds (not on cold launch — Apple guidance).

```swift
// In AppEnvironment or AdsService.init
func requestTrackingPermission() async {
    guard #available(iOS 14, *) else { return }
    let status = ATTrackingManager.trackingAuthorizationStatus
    guard status == .notDetermined else { return }
    // Brief delay so app is visible first
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    let result = await ATTrackingManager.requestTrackingAuthorization()
    // Log result to analytics
}
```

ATT status → analytics event `att_permission_response`.

---

## Ad Unit IDs

| Ad Type | Test ID | Prod ID (env var) |
|---------|---------|-------------------|
| Rewarded | `ca-app-pub-3940256099942544/1712485313` | `ADS_REWARDED_ID` |
| Interstitial | `ca-app-pub-3940256099942544/4411468910` | `ADS_INTERSTITIAL_ID` |

Prod IDs injected via Xcode build configuration (Debug vs Release xcconfig). Never hardcoded.

```swift
// AdsConfig.swift
enum AdsConfig {
    static var rewardedAdUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/1712485313"
        #else
        return Bundle.main.object(forInfoDictionaryKey: "ADS_REWARDED_ID") as! String
        #endif
    }
}
```

---

## RewardedAdCoordinator

```swift
// RewardedAdCoordinator.swift
@MainActor
final class RewardedAdCoordinator: NSObject, ObservableObject, GADFullScreenContentDelegate {
    @Published var isAdReady: Bool = false
    private var rewardedAd: GADRewardedAd?

    func loadAd() async {
        rewardedAd = try? await GADRewardedAd.load(
            withAdUnitID: AdsConfig.rewardedAdUnitID,
            request: GADRequest()
        )
        rewardedAd?.fullScreenContentDelegate = self
        isAdReady = rewardedAd != nil
    }

    func showAd(from rootVC: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd else { completion(false); return }
        ad.present(fromRootViewController: rootVC) {
            let reward = ad.adReward
            completion(reward.amount.intValue > 0)
        }
        rewardedAd = nil
        isAdReady = false
        // Pre-load next ad
        Task { await self.loadAd() }
    }

    // GADFullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { await loadAd() }
    }
}
```

---

## InterstitialAdCoordinator

```swift
// InterstitialAdCoordinator.swift
@MainActor
final class InterstitialAdCoordinator: NSObject, ObservableObject, GADFullScreenContentDelegate {
    @Published var isAdReady: Bool = false
    private var interstitialAd: GADInterstitialAd?
    private var showCount: Int = 0

    // Rate limiting: max 1 interstitial per session in v1
    var canShowAd: Bool { showCount == 0 && isAdReady }

    func loadAd() async { ... }

    func showAd(from rootVC: UIViewController) {
        guard canShowAd, let ad = interstitialAd else { return }
        ad.present(fromRootViewController: rootVC)
        showCount += 1
        interstitialAd = nil
        isAdReady = false
    }
}
```

---

## AdsService (Full Implementation)

```swift
// AdsService.swift
@MainActor
final class AdsService: ObservableObject {
    let rewarded = RewardedAdCoordinator()
    let interstitial = InterstitialAdCoordinator()

    @Published var isRewardedAdReady: Bool = false

    init() {
        Task {
            await rewarded.loadAd()
            await interstitial.loadAd()
        }
        // Propagate ready state
        rewarded.$isAdReady.assign(to: &$isRewardedAdReady)
    }

    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard let rootVC = UIApplication.shared.rootViewController else {
            completion(false); return
        }
        Task {
            await rewarded.showAd(from: rootVC, completion: completion)
        }
    }

    func showInterstitialIfReady() {
        guard let rootVC = UIApplication.shared.rootViewController else { return }
        Task {
            interstitial.showAd(from: rootVC)
        }
    }
}
```

---

## Ad Placement Rules (v1)

| Placement | Trigger | Condition |
|-----------|---------|-----------|
| Rewarded — hints | User taps hint with 0 remaining | Always available if ad loaded |
| Rewarded — continue after lose | User taps "Watch Ad" on lose screen | Always available if ad loaded |
| Interstitial — between levels | After win screen dismissed → before hub | Max 1 per session, only if ad loaded |

**NOT in v1:** Mid-game ads, banner ads, forced pre-game ads.

---

## SwiftUI Integration Pattern

Since AdMob requires `UIViewController`, wrap in a UIViewControllerRepresentable proxy or use `UIApplication.shared.topViewController()` helper.

```swift
extension UIApplication {
    var rootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
```

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `SharedServices/Ads/AdsService.swift` | Replace stub |
| `SharedServices/Ads/RewardedAdCoordinator.swift` | Create |
| `SharedServices/Ads/InterstitialAdCoordinator.swift` | Create |
| `SharedServices/Ads/AdsConfig.swift` | Create |
| `SmartGamesApp.swift` | Add GADMobileAds.start() + ATT |
| `Info.plist` | Add GADApplicationIdentifier, NSUserTrackingUsageDescription |
| `Package.swift` or `Podfile` | Add Google Mobile Ads SDK |

---

## Acceptance Criteria

- [ ] Test rewarded ad loads and shows in simulator (test ID)
- [ ] Reward callback fires after watching ad
- [ ] Hints replenished (+3) after rewarded ad
- [ ] Interstitial shown max once per session after win
- [ ] ATT prompt appears on first launch
- [ ] No ads shown during active gameplay
- [ ] Prod ad IDs configurable via build config without code change

---

## Tests Needed

- `AdsServiceTests` — mock coordinator, verify reward callback
- Manual: rewarded + interstitial flow on device with test IDs
- Manual: ATT prompt appears on fresh install

---

## Dependencies

- PR-07 (win/lose screens that trigger ads)
- PR-02 (AdsService stub exists)
