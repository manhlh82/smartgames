# AdMob Integration Guide

## Current State

The `AdsService`, `RewardedAdCoordinator`, and `InterstitialAdCoordinator` are fully implemented
with stub/simulation mode. The architecture is identical to production — only the actual SDK
calls are swapped out.

## To Activate Real AdMob

### 1. Add SDK via SPM

In Xcode: File → Add Package Dependencies
URL: `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`
Add `GoogleMobileAds` to SmartGames target.

### 2. Initialize in SmartGamesApp.swift

```swift
import GoogleMobileAds

// In SmartGamesApp init or AppDelegate:
GADMobileAds.sharedInstance().start(completionHandler: nil)
```

### 3. Replace stubs in RewardedAdCoordinator.swift

Replace `simulateAdPresentation` with:

```swift
func showAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
    guard let ad = rewardedAd else { completion(false); return }
    ad.present(fromRootViewController: viewController) {
        completion(true) // reward granted
    }
    rewardedAd = nil
    isAdReady = false
    Task { await loadAd() }
}

func loadAd() async {
    rewardedAd = try? await GADRewardedAd.load(
        withAdUnitID: AdsConfig.rewardedAdUnitID,
        request: GADRequest()
    )
    isAdReady = rewardedAd != nil
}

private var rewardedAd: GADRewardedAd?
```

### 4. Replace stub in InterstitialAdCoordinator.swift

```swift
func loadAd() async {
    interstitialAd = try? await GADInterstitialAd.load(
        withAdUnitID: AdsConfig.interstitialAdUnitID,
        request: GADRequest()
    )
    isAdReady = interstitialAd != nil
}

func showIfReady(from viewController: UIViewController) {
    guard canShowAd, let ad = interstitialAd else { return }
    ad.present(fromRootViewController: viewController)
    interstitialAd = nil
    isAdReady = false
    showCount += 1
    lastShowTime = Date()
    Task { await loadAd() }
}

private var interstitialAd: GADInterstitialAd?
```

### 5. Add ATT permission

Uncomment the ATT code in `SmartGamesApp.requestTrackingPermissionIfNeeded()`.

### 6. Update Info.plist

Replace `GADApplicationIdentifier` test value with real App ID from AdMob console.

### 7. Add to xcconfig

```
ADS_REWARDED_ID = ca-app-pub-YOUR_REAL_ID/YOUR_REWARDED_UNIT
ADS_INTERSTITIAL_ID = ca-app-pub-YOUR_REAL_ID/YOUR_INTERSTITIAL_UNIT
```
