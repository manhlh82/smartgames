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
        XCTAssertNotNil(env.gameRegistry)
    }

    func testGameRegistryHasSudoku() async {
        let env = await AppEnvironment()
        await MainActor.run {
            let sudoku = env.gameRegistry.module(for: "sudoku")
            XCTAssertNotNil(sudoku)
            XCTAssertEqual(sudoku?.id, "sudoku")
            XCTAssertTrue(sudoku?.isAvailable == true)
        }
    }

    func testHubViewModelLoadsFromRegistry() async {
        let env = await AppEnvironment()
        let vm = await HubViewModel()
        await MainActor.run {
            vm.loadGames(from: env.gameRegistry)
            XCTAssertFalse(vm.games.isEmpty)
            let sudoku = vm.games.first { $0.id == "sudoku" }
            XCTAssertNotNil(sudoku)
            XCTAssertTrue(sudoku?.isAvailable == true)
        }
    }

    func testAppRouterNavigate() async {
        let router = await AppRouter()
        await MainActor.run {
            XCTAssertTrue(router.path.isEmpty)
            router.navigate(to: .gameLobby(gameId: "sudoku"))
            XCTAssertEqual(router.path.count, 1)
            router.pop()
            XCTAssertTrue(router.path.isEmpty)
        }
    }
}
