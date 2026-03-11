import Foundation
import UserNotifications

/// Manages the daily Sudoku challenge — deterministic puzzle generation, streak tracking,
/// completion state persistence, and optional local push notification.
@MainActor
final class DailyChallengeService: ObservableObject {
    @Published var todayState: DailyChallengeState
    @Published var streak: DailyStreakData

    private let persistence: PersistenceService
    private let generator = SudokuGenerator()
    /// Cached puzzle for today — avoids regenerating on every access.
    private var cachedPuzzle: SudokuPuzzle?
    private var cachedPuzzleDateString: String?

    // MARK: - Init

    init(persistence: PersistenceService) {
        self.persistence = persistence
        let today = DailyChallengeService.utcDateString()
        self.todayState = persistence.load(DailyChallengeState.self,
                                           key: PersistenceService.Keys.sudokuDailyState)
                          ?? DailyChallengeState(dateString: today, isCompleted: false)
        self.streak = persistence.load(DailyStreakData.self,
                                       key: PersistenceService.Keys.sudokuDailyStreak)
                      ?? DailyStreakData()

        // Reset state if a new day has started
        if todayState.dateString != today {
            todayState = DailyChallengeState(dateString: today, isCompleted: false)
            persistence.save(todayState, key: PersistenceService.Keys.sudokuDailyState)
        }
    }

    // MARK: - Puzzle

    /// Returns today's deterministic puzzle (cached after first call).
    func todayPuzzle() -> SudokuPuzzle {
        let today = DailyChallengeService.utcDateString()
        if let cached = cachedPuzzle, cachedPuzzleDateString == today {
            return cached
        }
        let seed = SeededRandomNumberGenerator.seed(from: today)
        var rng = SeededRandomNumberGenerator(seed: seed)
        let puzzle = generator.generate(difficulty: todayDifficulty(), using: &rng)
        cachedPuzzle = puzzle
        cachedPuzzleDateString = today
        return puzzle
    }

    /// Difficulty rotates by day of week (UTC calendar).
    func todayDifficulty() -> SudokuDifficulty {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        // weekday: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
        let weekday = cal.component(.weekday, from: Date())
        switch weekday {
        case 1: return .easy    // Sunday
        case 2: return .easy    // Monday
        case 3: return .medium  // Tuesday
        case 4: return .hard    // Wednesday
        case 5: return .expert  // Thursday
        case 6: return .hard    // Friday
        case 7: return .medium  // Saturday
        default: return .medium
        }
    }

    // MARK: - Completion

    func isCompletedToday() -> Bool { todayState.isCompleted }

    /// Call when the player wins today's daily challenge.
    func markCompleted(elapsedSeconds: Int, mistakes: Int, stars: Int) {
        guard !todayState.isCompleted else { return }
        let today = DailyChallengeService.utcDateString()
        todayState.isCompleted = true
        todayState.elapsedSeconds = elapsedSeconds
        todayState.mistakes = mistakes
        todayState.stars = stars
        persistence.save(todayState, key: PersistenceService.Keys.sudokuDailyState)
        updateStreak(today: today)
    }

    // MARK: - Streak Logic

    private func updateStreak(today: String) {
        var updated = streak
        updated.completedDates.insert(today)

        if let last = updated.lastCompletedDate {
            if last == yesterday() {
                updated.currentStreak += 1
            } else if last == today {
                // Already counted — no-op (guard above prevents this, but be safe)
            } else {
                updated.currentStreak = 1
            }
        } else {
            updated.currentStreak = 1
        }

        updated.bestStreak = max(updated.bestStreak, updated.currentStreak)
        updated.lastCompletedDate = today
        streak = updated
        persistence.save(streak, key: PersistenceService.Keys.sudokuDailyStreak)
    }

    // MARK: - Notifications

    /// Schedule a repeating daily local notification at the given hour (local time, 24h).
    /// Cancels any existing daily reminder before scheduling to avoid duplicates.
    func scheduleReminderNotification(at hour: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])

        let content = UNMutableNotificationContent()
        content.title = "Daily Puzzle Ready"
        content.body = "Your daily Sudoku challenge is waiting!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminderNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    /// Request notification authorization from the user (call once on first enable).
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus == .authorized
        }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        return granted
    }

    // MARK: - Helpers

    private let notificationID = "smartgames.daily.reminder"

    /// Current UTC date as "yyyy-MM-dd".
    static func utcDateString(from date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt.string(from: date)
    }

    /// Yesterday's UTC date string.
    private func yesterday() -> String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return DailyChallengeService.utcDateString(from: yesterday)
    }
}
