# Firebase Analytics Integration Guide

## Current State
`AnalyticsService` logs to Xcode console (os.log) in DEBUG.
All events are defined as typed static factories — zero call-site changes needed when Firebase is integrated.

## To Activate Firebase Analytics

### 1. Add SDK via SPM in Xcode
File → Add Package Dependencies
URL: `https://github.com/firebase/firebase-ios-sdk`
Add: `FirebaseAnalytics` (and optionally `FirebaseCrashlytics`) to SmartGames target.

### 2. Add GoogleService-Info.plist
Download from Firebase Console → Project Settings → iOS App.
Add to Xcode project (do NOT commit to git — add to .gitignore).

### 3. Initialize in SmartGamesApp.swift
```swift
import Firebase

// In init() or as first statement in body:
FirebaseApp.configure()
```

### 4. Update AnalyticsService.swift
```swift
import FirebaseAnalytics

func log(_ event: AnalyticsEvent) {
    Analytics.logEvent(event.name, parameters: event.parameters as? [String: Any])
    #if DEBUG
    logger.debug("[Analytics] \(event.name)")
    #endif
}
```

### 5. Add GoogleService-Info.plist to .gitignore
```
GoogleService-Info.plist
```

## Key Dashboards to Build
1. Retention funnel: app_open → hub_viewed → sudoku_game_started → sudoku_game_completed
2. Difficulty distribution: sudoku_game_started group by difficulty
3. Monetization: sudoku_hint_exhausted → ad_rewarded_prompt_shown → ad_rewarded_completed
4. Error rate: sudoku_number_placed filter is_correct=false / total
