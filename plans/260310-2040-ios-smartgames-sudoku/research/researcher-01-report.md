# iOS Sudoku App Implementation Research Report

**Report Date:** March 10, 2026
**Researcher:** Claude Researcher Agent
**Focus:** iOS/Swift implementation feasibility and technical stack selection

---

## 1. Sudoku Puzzle Generation Algorithms

### Standard Algorithm: Backtracking + Constraint Propagation

**Recommended Approach:**
- **Generate:** Build complete valid 9x9 grid using backtracking with constraint propagation
- **Reduce:** Remove cells one-by-one while preserving unique solution
- **Validate:** Check solution uniqueness after each removal (critical)

**Performance Baseline:**
- Modern implementation: ~25-40 puzzles/second on standard hardware
- AC-3 algorithm (Arc Consistency) + MRV heuristic + Forward Checking = millisecond solving time
- Naked pair technique reduces DFS steps from 397 to 2 across 1M puzzles

### Difficulty Level Generation

**Clue Counts (Standard):**
- Easy: 38-45 clues (basic scanning + pencil marks)
- Medium: 36-40 clues (intermediate patterns, pairs)
- Hard: 30-35 clues (complex logic, X-Wings)
- Expert: 23-30 clues (advanced techniques, swordfish)
- Master: 26 clues (sophisticated heuristics)
- Extreme: 17-23 clues (expert-level pattern recognition)

**Critical Insight:** Difficulty NOT solely determined by clue count—position and required solving techniques matter equally. A well-placed 20-clue puzzle can exceed a poorly-placed 30-clue puzzle in difficulty.

**Implementation Strategy:**
1. Generate via standard backtracking
2. Remove clues based on difficulty parameter
3. After each removal, verify unique solution using constraint solver
4. Validate required solving techniques match difficulty level (optional refinement)

### Existing iOS Swift Reference Implementations
- Algorithm X implementation (Donald Knuth's technique) with MVVM architecture
- Constraint propagation libraries in open-source repos demonstrating efficiency
- Most use dependency injection for testability

**Pool Generation:** Generate puzzles offline or batch-load pre-generated puzzles. 40 puzzles/second means large pools feasible in background.

---

## 2. Google AdMob iOS Swift Integration (2024-2025)

### SDK Setup & Versions

**Latest Installation Methods:**
1. **Swift Package Manager (Recommended):**
   - URL: `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`
   - Xcode 16.0+ required
   - iOS 13.0+ target minimum

2. **CocoaPods:** Still supported via `pod 'Google-Mobile-Ads-SDK'`

3. **Manual Download:** Legacy option, not recommended

### Configuration Requirements

**Info.plist Additions:**
- `GADApplicationIdentifier`: Your AdMob app ID
- `SKAdNetworkItems`: Array of SKAdNetworkIdentifier values for Google + third-party buyers

**SDK Initialization:**
```swift
import GoogleMobileAds

// Call BEFORE loading ads, preferably in AppDelegate or App struct
MobileAds.shared.start()
```

**Important:** Initialize before requesting user consent in regulated regions (EEA)

### Ad Formats for Game Monetization

| Format | Use Case | User Action | Best Practice |
|--------|----------|------------|----------------|
| **Banner** | Persistent, non-intrusive | Optional view | Bottom of screen, after gameplay |
| **Interstitial** | Full-screen between levels | Auto-show | Level transitions, game over screens |
| **Rewarded** | User-initiated reward | Opt-in | Extra lives, hints, continues |
| **Rewarded Interstitial** (NEW) | Automatic reward ads | Auto-show with opt-out | Level transitions without user initiation |

### API Implementation Summary

**Rewarded Ads Load & Display:**
```swift
GADRewardedAd.load(adUnitID: String, request: GADRequest)
// Register: GADFullScreenContentDelegate
rewardedAd.present(from: UIViewController) // Triggers reward event
```

**Key Delegates:**
- `adDidRecordImpression()`: Track ad display
- `adDidRecordClick()`: User interaction tracking
- `adWillPresentFullScreen()`: Pause game logic
- `adWillDismissFullScreen()`: Resume game

### Server-Side Verification (SSV)
Optional but recommended: Validate reward server-side using custom data parameter to prevent fraud.

---

## 3. SwiftUI Game Architecture Patterns

### Recommended Multi-Game App Structure

**Core Pattern: MVVM + Coordinator/Router**

**State Management Layer:**
- Centralized Router/Coordinator: Manages NavigationStack and navigation paths
- Feature-level ViewModels: Isolated state per game/screen
- Shared Services via EnvironmentObject: User settings, profile, analytics

**View Hierarchy:**
```
App
├── Router (manages NavigationPath)
├── Environment Objects:
│   ├── UserSettings (audio, difficulty)
│   ├── AnalyticsService
│   └── GameStateManager
└── Views:
    ├── HomeView (game selection)
    ├── SudokuGameView (game-specific logic)
    └── ProfileView
```

### ViewModel Pattern (2024-2025 Best Practices)

**iOS 17+ Recommendation:** Use `@Observable` macro instead of `ObservableObject`

```swift
@Observable
class SudokuGameViewModel {
    var board: [[Int]]
    var selectedCell: (Int, Int)?

    func makeMove(row: Int, col: Int, value: Int) { }
}
```

**Pre-iOS 17 Pattern:**
```swift
class SudokuGameViewModel: ObservableObject {
    @Published var board: [[Int]] = []
    @MainActor // For UI updates
    func updateBoard() { }
}
```

### Navigation Architecture

**NavigationStack Setup:**
```swift
@State var navigationPath: NavigationPath = NavigationPath()

NavigationStack(path: $navigationPath) {
    HomeView()
        .navigationDestination(for: GameRoute.self) { route in
            switch route {
            case .sudoku:
                SudokuGameView()
            }
        }
}
```

**Router Methods:**
- `push(route)`: Append to navigation stack
- `pop()`: Remove last route
- `popToRoot()`: Clear all navigation

### Multi-Game App Considerations

**Separate Feature Folders:**
```
Sources/
├── Shared/
│   ├── Models/
│   ├── Services/
│   └── UI/
├── Sudoku/
│   ├── ViewModels/
│   ├── Views/
│   └── Models/
├── OtherGame/
│   ├── ViewModels/
│   ├── Views/
│   └── Models/
```

**Shared vs. Isolated State:**
- Isolated: Game board, move history (per-game)
- Shared: User profile, high scores, settings (via EnvironmentObject)

**Dependency Injection:** Pass services through initializers for testability; use EnvironmentObject only for truly global state.

---

## 4. iOS Game Data Persistence Strategy

### Framework Comparison

| Aspect | UserDefaults | CoreData | SwiftData |
|--------|--------------|----------|-----------|
| **Best For** | Settings, small booleans | Large datasets, complex schemas | Modern SwiftUI apps, iOS 17+ |
| **Size Limit** | ~4KB practical | Unlimited (SQLite) | Unlimited (SQLite) |
| **Syntax** | Simple key-value | Complex, verbose | Swift-native, modern |
| **SwiftUI Integration** | @AppStorage | Manual, verbose | Native @Query, @Environment |
| **iOS Requirement** | All iOS versions | iOS 3.0+ | iOS 17+ |
| **iCloud Sync** | Requires CloudKit | Built-in | Built-in |
| **Learning Curve** | Trivial | Steep | Moderate |
| **Performance (Small) | ~100ms | ~50ms | ~50ms |
| **Mature** | Very | Battle-tested | New (1 year) |

### Recommended Strategy for Sudoku Game

**Implementation Mix:**

1. **UserDefaults + @AppStorage (Settings & Quick Access)**
   - Audio toggle, difficulty preference
   - High scores (if < 100 games)
   - Last played game metadata
   ```swift
   @AppStorage("audioEnabled") var audioEnabled: Bool = true
   @AppStorage("difficulty") var preferredDifficulty: String = "Medium"
   ```

2. **SwiftData (Game Progress & History)** — iOS 17+
   - Current game state (board, moves, timer)
   - Game history (past games, statistics)
   - User profiles in multiplayer scenarios
   - Automatic iCloud sync
   ```swift
   @Query var savedGames: [SavedGame]
   ```

3. **CoreData Fallback (iOS < 17)**
   - Same use cases as SwiftData
   - More setup required but mature and stable

### Data Persistence Model for Sudoku

**SavedGame Entity:**
```swift
@Model
final class SavedGame {
    var id: UUID
    var createdAt: Date
    var completedAt: Date?
    var board: [[Int]] // Current board state
    var solution: [[Int]]
    var difficulty: String
    var moveHistory: [Move]
    var hints_used: Int
    var time_elapsed: TimeInterval
}
```

### Performance Considerations

- SwiftData/CoreData differences negligible for games with <5000 saved states
- For high-score leaderboards (>10k entries), consider CloudKit with CoreData
- Batch saves every 30 seconds or on major checkpoints (avoid constant writes)

**Practical Recommendation:** SwiftData for iOS 17+, CoreData for earlier versions. UserDefaults only for toggles/preferences.

---

## 5. AppTrackingTransparency (ATT) Requirements

### Legal & Technical Framework

**iOS Requirement:** iOS 14.5+ (launched April 2021)
**Mandatory If:** App uses IDFA or shares user data with third parties for ad targeting

### When to Show ATT Prompt

**Timing Considerations:**

1. **Recommended:** During first app launch or onboarding flow
2. **Strategic:** Just before showing first ad (relevant context)
3. **Alternative:** In settings/privacy section (optional re-prompt)

**Key Constraint:** Can only prompt ONCE per app install (user can change in Settings > Privacy > Tracking)

### Implementation Workflow

**Step 1: Declare Intent in App Store**
- Privacy section submission must specify:
  - What data is tracked (IDFA)
  - Purpose (ad targeting, analytics)
  - Categories affected

**Step 2: Request Permission in Code**
```swift
import AppTrackingTransparency

ATTrackingManager.requestTrackingAuthorization { status in
    switch status {
    case .authorized:
        print("User approved tracking")
        // Load personalized ads
    case .denied:
        print("User declined")
        // Load non-personalized ads
    case .notDetermined:
        // Not yet prompted
    case .restricted:
        // Parental controls or MDM
    @unknown default:
        break
    }
}
```

**Step 3: Integrate with Ad SDK**
- Wait for ATT response before initializing Google Mobile Ads
- Pass tracking authorization status to AdMob
- Adjust personalization based on user choice

### Critical Timing Decision

**For Sudoku Game:**
- **Early Prompt:** Show during onboarding (maximizes opt-in rates ~25-40%)
- **Late Prompt:** Show after first completed puzzle (more context, lower rates ~15-25%)
- **Best Practice:** Offer value proposition first ("Help us show relevant ads")

### COPPA Compliance (Children)

If app targets users under 13:
- Cannot request ATT
- Must disable personalized ads entirely
- Use `tagForUnderAgeOfConsent()` in AdMob SDK

---

## Summary Table: Tech Stack Recommendations

| Component | Choice | Why |
|-----------|--------|-----|
| **Puzzle Generation** | Backtracking + Constraint Propagation | Proven standard, ~40 puzzles/sec, tunable difficulty |
| **Ad Framework** | Google AdMob (SPM) | Market leader, best integration, Rewarded Interstitial support |
| **UI Framework** | SwiftUI + MVVM + NavigationStack | Modern, scalable, state management clear |
| **Data Persistence** | SwiftData (iOS 17+) + UserDefaults | Simple, native iCloud, avoids CoreData verbosity |
| **Privacy Layer** | ATT during onboarding | Maximize opt-in, set realistic expectations |

---

## Unresolved Questions

1. **Puzzle Pool Scale:** Will app ship with pre-generated puzzles or generate on-demand? Storage implications?
2. **Multiplayer Support:** Any planned competitive/social features requiring backend sync?
3. **Monetization Strategy:** Freemium model (ads + IAP) or ads-only? Impacts priority of ATT/AdMob setup.
4. **iOS 16 Support:** Must app support iOS 16? (Affects SwiftData vs CoreData choice)
5. **Hint/Solver Logic:** Should app include AI solver for hints? Impacts complexity budget.

---

## Sources

### Sudoku Algorithms & Generation
- [GitHub - Sudoku puzzle generator iOS (Algorithm X)](https://github.com/sashankg/Sudoku)
- [GitHub - SwiftSudoku with AI solver](https://github.com/stevenabreu7/SwiftSudoku)
- [Solving N×N Sudoku with Backtracking](https://blog.kedarbasutkar.com/solving-sudoku-with-backtracking)
- [Sudoku solving algorithms - Wikipedia](https://en.wikipedia.org/wiki/Sudoku_solving_algorithms)
- [Sudoku Difficulty Levels Explained](https://www.sudokupuzzles.net/blog/sudoku-difficulty-levels-explained-easy-to-extreme)
- [Generating difficult Sudoku puzzles quickly](https://dlbeer.co.nz/articles/sudoku.html)
- [Solving Sudoku Like a Human - Heuristic Strategies](https://medium.com/@safalnarsingh/solving-sudoku-like-a-human-heuristic-strategies-and-puzzle-generation-25ea9cf0da26)

### Google AdMob Integration
- [Google Mobile Ads SDK - Quick Start](https://developers.google.com/admob/ios/quick-start)
- [Rewarded Ads - iOS](https://developers.google.com/admob/ios/rewarded)
- [Rewarded Interstitial Ads - iOS](https://developers.google.com/admob/ios/rewarded-interstitial)
- [How to Implement Google Ads in iOS (Swift) - Medium 2025](https://medium.com/@garejakirit/how-to-implement-google-ads-in-ios-swift-2ad1d049634d)
- [AdMob Integration SwiftUI Tutorial](https://ix76y.medium.com/how-to-integrate-admob-rewarded-ads-with-swiftui-3d6c2325c1c4)
- [GitHub - Swifty-Ads (GDPR/COPPA/ATT compliant wrapper)](https://github.com/crashoverride777/swifty-ads)

### SwiftUI Architecture & Navigation
- [Complete Guide to MVVM in SwiftUI](https://www.swiftanytime.com/blog/mvvm-in-swiftui)
- [Exploring Scalable SwiftUI Navigation](https://nikita-goncear.medium.com/exploring-scalable-swiftui-navigation-30f8438e9d6d)
- [Clean Architecture for SwiftUI](https://nalexn.github.io/clean-architecture-swiftui/)
- [Modern SwiftUI Navigation 2025](https://medium.com/@dinaga119/mastering-navigation-in-swiftui-the-2025-guide-to-clean-scalable-routing-bbcb6dbce929)
- [How to Structure SwiftUI Project 2026](https://dev.to/__be2942592/how-to-structure-a-swiftui-project-in-2026-41m8)
- [EnvironmentObject in SwiftUI](https://www.avanderlee.com/swiftui/environmentobject/)

### Data Persistence
- [Complete Guide to iOS Data Persistence](https://byby.dev/ios-persistence)
- [Data Persistence in SwiftUI - Kodeco](https://www.kodeco.com/ios/paths/sharing-state-management-swiftui/43760166-data-persistence-in-swiftui)
- [When to use UserDefaults, Keychain, or Core Data](https://fluffy.es/persist-data/)
- [Mastering SwiftData](https://commitstudiogs.medium.com/mastering-swiftdata-apples-new-way-to-persist-your-app-s-data-50aac9265fe2)
- [Measuring Core Data and SwiftData](https://yaacoub.github.io/articles/swift-tip/measuring-core-data-and-swiftdata/)

### AppTrackingTransparency
- [AppTrackingTransparency Overview](https://www.appsflyer.com/glossary/app-tracking-transparency/)
- [ATT: Apple's User Privacy Framework](https://adapty.io/blog/app-tracking-transparency/)
- [Apple Support: If an app asks to track your activity](https://support.apple.com/en-us/102420)
- [What is ATT - Adjust](https://www.adjust.com/glossary/app-tracking-transparency/)
- [Mastering IDFA Opt-In Rates - Playwire](https://www.playwire.com/blog/mastering-idfa-opt-in-rates-the-complete-apptrackingtransparency-guide-for-ios-apps)
