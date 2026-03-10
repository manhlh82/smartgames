import XCTest
@testable import SmartGames

final class MockAnalyticsService: AnalyticsServiceProtocol {
    var loggedEvents: [AnalyticsEvent] = []
    func log(_ event: AnalyticsEvent) { loggedEvents.append(event) }
}

final class AnalyticsEventTests: XCTestCase {
    func testAppLifecycleEvents_HaveCorrectNames() {
        XCTAssertEqual(AnalyticsEvent.hubViewed.name, "hub_viewed")
        XCTAssertEqual(AnalyticsEvent.settingsOpened.name, "settings_opened")
        XCTAssertEqual(AnalyticsEvent.attPermissionShown.name, "att_permission_shown")
    }

    func testSudokuEvents_HaveCorrectNamesAndParams() {
        let startEvent = AnalyticsEvent.sudokuGameStarted(difficulty: "easy", isResume: false)
        XCTAssertEqual(startEvent.name, "sudoku_game_started")
        XCTAssertEqual(startEvent.parameters["difficulty"] as? String, "easy")
        XCTAssertEqual(startEvent.parameters["is_resume"] as? Bool, false)

        let completeEvent = AnalyticsEvent.sudokuGameCompleted(
            difficulty: "medium", elapsedSeconds: 120, mistakes: 1, hintsUsed: 2, stars: 2)
        XCTAssertEqual(completeEvent.name, "sudoku_game_completed")
        XCTAssertEqual(completeEvent.parameters["stars"] as? Int, 2)
        XCTAssertEqual(completeEvent.parameters["mistakes"] as? Int, 1)
    }

    func testAdEvents_HaveCorrectNames() {
        let promptEvent = AnalyticsEvent.adRewardedPromptShown(reason: "hints", difficulty: "hard")
        XCTAssertEqual(promptEvent.name, "ad_rewarded_prompt_shown")
        XCTAssertEqual(promptEvent.parameters["reason"] as? String, "hints")

        let completedEvent = AnalyticsEvent.adRewardedCompleted(reason: "hints")
        XCTAssertEqual(completedEvent.name, "ad_rewarded_completed")
    }

    func testMockAnalyticsService_RecordsEvents() {
        let mock = MockAnalyticsService()
        mock.log(.hubViewed)
        mock.log(.sudokuGameStarted(difficulty: "easy", isResume: false))
        XCTAssertEqual(mock.loggedEvents.count, 2)
        XCTAssertEqual(mock.loggedEvents[0].name, "hub_viewed")
        XCTAssertEqual(mock.loggedEvents[1].name, "sudoku_game_started")
    }
}
