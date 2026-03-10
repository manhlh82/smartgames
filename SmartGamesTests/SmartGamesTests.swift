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

    func testHubViewModelHasSudoku() async {
        let vm = await HubViewModel()
        await MainActor.run {
            XCTAssertFalse(vm.games.isEmpty)
            let sudoku = vm.games.first { $0.id == "sudoku" }
            XCTAssertNotNil(sudoku)
            XCTAssertTrue(sudoku?.isAvailable == true)
            XCTAssertNotNil(sudoku?.route)
        }
    }

    func testAppRouterNavigate() async {
        let router = await AppRouter()
        await MainActor.run {
            XCTAssertTrue(router.path.isEmpty)
            router.navigate(to: .sudokuLobby)
            XCTAssertEqual(router.path.count, 1)
            router.pop()
            XCTAssertTrue(router.path.isEmpty)
        }
    }
}
