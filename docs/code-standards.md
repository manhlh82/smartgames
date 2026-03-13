# Code Standards

## Principles

YAGNI · KISS · DRY

## Swift

- PascalCase types, camelCase properties/functions
- Max 200 lines/file — split if exceeded
- `@MainActor final class` for ViewModels and Services
- Engine files: zero UIKit/SwiftUI imports
- Services: `@MainActor ObservableObject` with `@Published` properties

## Theme System (Phase 2+)

- Define color palettes in `BoardTheme` struct (one per theme variant)
- Inject `ThemeService` via `@EnvironmentObject` in views
- Read colors via `@EnvironmentObject var theme: ThemeService`, access `theme.current.{colorToken}`
- Theme preference persisted via `SettingsService`

## Statistics & Streaks (Phase 2+)

- Track stats per difficulty in `SudokuStats` struct
- Streaks: consecutive wins reset on loss; track `currentStreak` and `bestStreak`
- Aggregate across difficulties for "All" view
- Record both wins and losses to `StatisticsService`

## Daily Challenge (Phase 2+)

- Use `SeededRandomNumberGenerator` for deterministic puzzle generation
- Derive seed from UTC date string for timezone consistency
- Track completion state and streak per calendar day
- Schedule local push notifications via `UNUserNotificationCenter`

## Game Center Integration (Phase 2+)

- Authenticate on app launch (silent if previously authed)
- Submit scores asynchronously; never block game flow
- Leaderboard IDs: `com.smartgames.sudoku.leaderboard.{difficulty}`
- Use native `GKGameCenterViewController` for leaderboard display

## In-App Purchases (Phase 2+)

- Use StoreKit 2 async/await API (iOS 15+; our min is iOS 16+)
- Non-consumable products (e.g., Remove Ads) verified via `Transaction.currentEntitlements`
- Consumable products (e.g., Hint Pack) grant immediately on verified transaction
- Listen to `Transaction.updates` for refunds, family sharing, and interrupted purchases
- Local cache is convenience only; `currentEntitlements` is source of truth
- Hint pack grants +12 hints, bypasses `monetizationConfig.maxHintCap`

## Monetization & Ads (Phase 2.6+)

- Per-game `MonetizationConfig` struct (banner, interstitial frequency, hint rewards, mistake reset)
- Games provide `monetizationConfig` property via `GameModule` protocol
- `BannerAdCoordinator` manages bottom banner lifecycle (load, impression, failure)
- `InterstitialAdCoordinator` shows after N levels; no session-level cap (frequency controlled by config)
- Rewarded hint flow: block input → show rewarded ad → on completion grant +3 hints (capped)
- Mistake reset flow: on mistake limit → show `needsMistakeResetAd` phase → on reward grant reset
- Hint balance persisted per game; mistake reset uses tracked per-level (max 1)
- Log all ad/monetization events via factories in `AnalyticsEvent+Ads.swift`

## Analytics Events

snake_case names, dot-namespaced params. Add factories to `AnalyticsEvent+{Domain}.swift`.

## Persistence Keys

Dot-separated in `PersistenceService.Keys`. Never hardcode strings at call sites.
Examples: `sudoku.stats.easy`, `sudoku.daily.state`, `store.adsRemoved`

## New Game Checklist (Modular Architecture)

1. Create `Games/{Name}/` folder with: `Engine/`, `Models/`, `ViewModels/`, `Views/`
2. Implement `{Name}GameModule: GameModule` protocol in game module root
   - Set `id`, `displayName`, `iconName`, `isAvailable`
   - Provide `monetizationConfig` (override for custom ad behavior)
   - Implement `makeLobbyView(environment:)` → return AnyView
   - Implement `navigationDestination(for:environment:)` → return AnyView? for routes
3. Create game-specific services (e.g., `ThemeService`, `StatisticsService`) owned by the module
4. Inject `MonetizationConfig` into game view models; use config to gate ad display
5. No shared-service imports in Engine files (Engine is pure game logic)
6. Register module in `AppEnvironment.init()`: `registry.register({Name}GameModule(...))`
7. Add game routes to `AppRoute` enum (e.g., `.gameLobby(gameId:)`, `.gamePlay(gameId:context:)`)
8. Add analytics events: `AnalyticsEvent+{Name}.swift` with snake_case event names
9. Update navigation: `HubView` reads games from `GameRegistry`, no hardcoding
