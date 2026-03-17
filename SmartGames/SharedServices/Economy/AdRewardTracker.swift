import Foundation

/// Tracks daily rewarded-ad gold grants to enforce the per-day cap.
/// Continue and undo ads bypass this cap — only gold-reward ads are counted.
@MainActor
final class AdRewardTracker: ObservableObject {

    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
    }

    // MARK: - Public API

    /// Returns true if the player can still earn gold from a rewarded ad today.
    var canEarnGoldFromAd: Bool {
        resetIfNewDay()
        return todayCount < EconomyConfig.adWatchDailyMax
    }

    /// Returns the current ad-watch count for today.
    var todayCount: Int {
        resetIfNewDay()
        return persistence.load(Int.self, key: PersistenceService.Keys.adRewardCount) ?? 0
    }

    /// Records a gold-reward ad watch. Call only when actually granting gold.
    func recordGoldAdWatch() {
        resetIfNewDay()
        let count = (persistence.load(Int.self, key: PersistenceService.Keys.adRewardCount) ?? 0) + 1
        persistence.save(count, key: PersistenceService.Keys.adRewardCount)
    }

    // MARK: - Private

    /// Resets the count when the calendar day has changed.
    private func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        if let savedDate = persistence.load(Date.self, key: PersistenceService.Keys.adRewardDate) {
            let savedDay = Calendar.current.startOfDay(for: savedDate)
            if savedDay < today {
                persistence.save(0, key: PersistenceService.Keys.adRewardCount)
                persistence.save(today, key: PersistenceService.Keys.adRewardDate)
            }
        } else {
            persistence.save(today, key: PersistenceService.Keys.adRewardDate)
        }
    }
}
