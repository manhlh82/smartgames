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

## Analytics Events

snake_case names, dot-namespaced params. Add factories to `AnalyticsEvent+{Domain}.swift`.

## Persistence Keys

Dot-separated in `PersistenceService.Keys`. Never hardcode strings at call sites.
Examples: `sudoku.stats.easy`, `sudoku.daily.state`, `store.adsRemoved`

## New Game Checklist

- [ ] `Games/{Name}/` folder with Engine/, Models/, ViewModels/, Views/
- [ ] No shared-service imports in Engine files
- [ ] `GameEntry` added to `HubViewModel.games`
- [ ] Route added to `AppRoute` enum
- [ ] Analytics events added to `AnalyticsEvent+{Name}.swift`
