# Phase 02 — Shared Services

**Priority:** Critical | **Effort:** M | **PR:** PR-02

---

## Overview

Implement all shared services that every game module will consume. These are injected as `@EnvironmentObject` at app root. Sudoku (and future games) depend on these but do not own them.

Services: Persistence, Settings, Sound, Haptics, Analytics (stub), Ads (stub).

---

## PR-02 Goal

Implement fully working PersistenceService, SettingsService, SoundService, HapticsService. Stub AnalyticsService and AdsService (real implementations in PR-08 and PR-09).

---

## 1. PersistenceService

**Strategy:** JSON + UserDefaults for game state. Simple, no CoreData overhead for v1.

```swift
// PersistenceService.swift
final class PersistenceService: ObservableObject {
    // Saves/loads Codable game states keyed by game ID
    func save<T: Codable>(_ value: T, key: String)
    func load<T: Codable>(_ type: T.Type, key: String) -> T?
    func delete(key: String)
}
```

**Keys used by Sudoku:**
- `sudoku.activeGame` — current in-progress game state (auto-saved every move)
- `sudoku.stats.{difficulty}` — per-difficulty stats (games played, best time, win %)
- `sudoku.hints.remaining` — free hints balance
- `app.settings` — global settings

**Save triggers:**
- Every cell value change (debounced 500ms)
- On `scenePhase == .background`
- On pause

---

## 2. SettingsService

```swift
final class SettingsService: ObservableObject {
    @Published var isSoundEnabled: Bool
    @Published var isHapticsEnabled: Bool
    @Published var highlightRelatedCells: Bool   // default: true
    @Published var highlightSameNumbers: Bool     // default: true
    @Published var showMistakeLimit: Bool         // default: true (3 mistakes → game over)
    @Published var showTimer: Bool               // default: true
}
```

Persisted via PersistenceService on every change.

---

## 3. SoundService

```swift
final class SoundService: ObservableObject {
    func playTap()
    func playError()
    func playWin()
    func playHint()
}
```

Uses `AVAudioPlayer` with pre-loaded `.caf` files. Respects `SettingsService.isSoundEnabled`. No external dependency.

---

## 4. HapticsService

```swift
final class HapticsService {
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle)
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType)
    func selection()
}
```

Wraps `UIFeedbackGenerator`. Respects `SettingsService.isHapticsEnabled`.

Triggers:
- Cell tap → `.light` impact
- Number placed → `.medium` impact
- Error → `.error` notification
- Win → `.success` notification

---

## 5. AnalyticsService (Stub)

```swift
protocol AnalyticsServiceProtocol {
    func log(_ event: AnalyticsEvent)
}

final class AnalyticsService: ObservableObject, AnalyticsServiceProtocol {
    func log(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[Analytics] \(event.name) \(event.parameters)")
        #endif
        // Real implementation in PR-09
    }
}

struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]
}
```

---

## 6. AdsService (Stub)

```swift
protocol AdsServiceProtocol {
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void)
    func showInterstitialAd(from viewController: UIViewController)
    var isRewardedAdReady: Bool { get }
}

final class AdsService: ObservableObject, AdsServiceProtocol {
    @Published var isRewardedAdReady: Bool = false

    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        // Stub — real implementation in PR-08
        completion(true) // Always reward in dev
    }

    func showInterstitialAd(from viewController: UIViewController) {
        // Stub
    }
}
```

---

## AppEnvironment

```swift
// AppEnvironment.swift — injected at SmartGamesApp root
class AppEnvironment: ObservableObject {
    let persistence = PersistenceService()
    let settings = SettingsService()
    let sound = SoundService()
    let haptics = HapticsService()
    let analytics = AnalyticsService()
    let ads = AdsService()
}
```

Injected via:
```swift
ContentView()
    .environmentObject(env.persistence)
    .environmentObject(env.settings)
    .environmentObject(env.sound)
    .environmentObject(env.analytics)
    .environmentObject(env.ads)
```

---

## SettingsView

Basic settings sheet accessible from hub gear icon:
- Sound toggle
- Haptics toggle
- Highlight settings
- Timer visibility
- Privacy Policy / Terms links

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `SharedServices/Persistence/PersistenceService.swift` | Create |
| `SharedServices/Settings/SettingsService.swift` | Create |
| `SharedServices/Settings/SettingsView.swift` | Create |
| `SharedServices/Sound/SoundService.swift` | Create |
| `SharedServices/Sound/HapticsService.swift` | Create |
| `SharedServices/Analytics/AnalyticsService.swift` | Create |
| `SharedServices/Analytics/AnalyticsEvent.swift` | Create |
| `SharedServices/Ads/AdsService.swift` | Create |
| `AppEnvironment.swift` | Create |
| `SmartGamesApp.swift` | Modify — inject AppEnvironment |

---

## Acceptance Criteria

- [ ] Settings persist across app launches (sound/haptics toggles survive kill/relaunch)
- [ ] Sound plays on tap (when enabled)
- [ ] Haptics fire on tap (when enabled)
- [ ] AnalyticsService.log() prints to console in DEBUG
- [ ] AdsService stub always grants reward
- [ ] SettingsView accessible from hub gear icon

---

## Tests Needed

- `PersistenceServiceTests` — save/load/delete round-trip for Codable structs
- `SettingsServiceTests` — settings persist and publish changes
- Manual: sound/haptics toggle works

---

## Dependencies

- PR-01 (folder structure must exist)
