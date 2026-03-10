import XCTest
@testable import SmartGames

final class SmartGamesTests: XCTestCase {
    func testAppEnvironmentCreation() {
        let env = AppEnvironment()
        XCTAssertNotNil(env.persistence)
        XCTAssertNotNil(env.settings)
        XCTAssertNotNil(env.sound)
        XCTAssertNotNil(env.analytics)
        XCTAssertNotNil(env.ads)
    }

    func testHubViewModelHasSudoku() {
        let vm = HubViewModel()
        XCTAssertFalse(vm.games.isEmpty)
        XCTAssertTrue(vm.games.contains { $0.id == "sudoku" })
        XCTAssertTrue(vm.games.first { $0.id == "sudoku" }?.isAvailable == true)
    }
}
