# Phase 05 — Daily Challenge

## Context Links
- [plan.md](plan.md) — overview
- Pattern ref: `SmartGames/Games/DropRush/Services/DropRushDailyChallengeService.swift`
- Pattern ref: `SmartGames/Games/DropRush/Models/DropRushDailyChallengeModels.swift`

## Overview
- **Priority:** P2
- **Status:** pending
- Daily challenge system: deterministic puzzle selection from seed, streak tracking, gold rewards, GameCenter leaderboard.

## Key Insights
- Follow `DropRushDailyChallengeService` pattern exactly
- Use `SeededRandomNumberGenerator` with UTC date string seed
- Day-of-week difficulty: weekdays = standard (9x9), weekends = mini (5x5)
- Score = inverse time (higher = faster), submitted to GameCenter
- Streak tracks consecutive daily completions

## Requirements

### CrosswordDailyChallengeModels.swift
```
struct CrosswordDailyChallengeState: Codable, Equatable
  - dateString: String
  - isCompleted: Bool
  - timeSeconds: Int?
  - hintsUsed: Int?
  - stars: Int?

struct CrosswordDailyStreakData: Codable
  - currentStreak: Int = 0
  - bestStreak: Int = 0
  - lastCompletedDate: String?
```

### CrosswordDailyChallengeService.swift
```
@MainActor final class CrosswordDailyChallengeService: ObservableObject
  @Published var todayState: CrosswordDailyChallengeState
  @Published var streak: CrosswordDailyStreakData

  init(persistence:, gold:, gameCenter:)
  func todayPuzzle(bank: CrosswordPuzzleBank) -> CrosswordPuzzle
  func todayDifficultyLabel() -> String
  func isCompletedToday() -> Bool
  func markCompleted(timeSeconds:, hintsUsed:, stars:)
  private func updateStreak(today:)
```

- `todayPuzzle`: seed from UTC date → pick puzzle index from appropriate difficulty pool
- Day-of-week mapping: Mon-Fri → standard pool, Sat-Sun → mini pool
- `markCompleted`: persist state, earn gold (EconomyConfig.dailyChallengeCompleteGold + 3-star bonus), submit GameCenter score, update streak

### CrosswordDailyChallengeView (optional in Phase 4 lobby)
- Entry point in lobby showing today's challenge, difficulty label, streak
- "Play" navigates to CrosswordGameView with daily puzzle
- Show completion status if already done today

## Related Code Files
- **Create:** `SmartGames/Games/Crossword/Models/CrosswordDailyChallengeModels.swift`
- **Create:** `SmartGames/Games/Crossword/Services/CrosswordDailyChallengeService.swift`
- **Modify:** `SmartGames/Games/Crossword/Views/CrosswordLobbyView.swift` — add daily challenge section

## Implementation Steps
1. Create `CrosswordDailyChallengeModels.swift` — state + streak structs
2. Create `CrosswordDailyChallengeService.swift` — follow DropRush pattern
3. Add persistence keys: `crossword.daily.state`, `crossword.daily.streak`
4. Add GameCenter leaderboard ID constant: `com.smartgames.crossword.leaderboard.daily`
5. Update `CrosswordLobbyView` — add daily challenge card
6. Wire daily challenge puzzle into CrosswordGameView navigation
7. Compile check

## Todo List
- [ ] CrosswordDailyChallengeModels
- [ ] CrosswordDailyChallengeService
- [ ] Persistence keys for daily state + streak
- [ ] GameCenter leaderboard ID
- [ ] Lobby daily challenge section
- [ ] Daily puzzle navigation flow
- [ ] Compile check

## Success Criteria
- Same puzzle returned for same UTC date
- Different puzzles on different days
- Streak increments on consecutive days
- Streak resets on missed day
- Gold reward granted on completion
- GameCenter score submitted
- Lobby shows completion status correctly
