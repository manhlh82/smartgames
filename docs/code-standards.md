# Code Standards

## Principles

YAGNI · KISS · DRY

## Swift

- PascalCase types, camelCase properties/functions
- Max 200 lines/file — split if exceeded
- `@MainActor final class` for ViewModels
- Engine files: zero UIKit/SwiftUI imports

## Analytics Events

snake_case names, dot-namespaced params. Add factories to `AnalyticsEvent+{Domain}.swift`.

## Persistence Keys

Dot-separated in `PersistenceService.Keys`. Never hardcode strings at call sites.

## New Game Checklist

- [ ] `Games/{Name}/` folder with Engine/, Models/, ViewModels/, Views/
- [ ] No shared-service imports in Engine files
- [ ] `GameEntry` added to `HubViewModel.games`
- [ ] Route added to `AppRoute` enum
- [ ] Analytics events added to `AnalyticsEvent+{Name}.swift`
