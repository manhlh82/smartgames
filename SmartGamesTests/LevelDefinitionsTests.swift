import XCTest
@testable import SmartGames

final class LevelDefinitionsTests: XCTestCase {

    func testLevels_Count_Is50() {
        XCTAssertEqual(LevelDefinitions.levels.count, 50)
    }

    func testLevel_ValidIndex_ReturnsConfig() {
        let config = LevelDefinitions.level(1)
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.levelNumber, 1)
    }

    func testLevel_InvalidIndex_ReturnsNil() {
        XCTAssertNil(LevelDefinitions.level(0))
        XCTAssertNil(LevelDefinitions.level(51))
    }

    func testLevels_DifficultyScalesUp() {
        guard let easy = LevelDefinitions.level(1),
              let hard = LevelDefinitions.level(50) else {
            XCTFail("Levels 1 and 50 should exist")
            return
        }
        // Later levels should have more objects
        XCTAssertGreaterThan(hard.totalObjects, easy.totalObjects)
        // Later levels should be faster (higher base speed)
        XCTAssertGreaterThan(hard.baseSpeed, easy.baseSpeed)
    }

    func testLevels_EachHasNonEmptySymbolPool() {
        for level in LevelDefinitions.levels {
            XCTAssertFalse(level.symbolPool.isEmpty, "Level \(level.levelNumber) has empty symbol pool")
        }
    }

    func testLevels_EachHasPositiveTotalObjects() {
        for level in LevelDefinitions.levels {
            XCTAssertGreaterThan(level.totalObjects, 0, "Level \(level.levelNumber) has 0 total objects")
        }
    }

    func testLevels_EachHasPositiveBaseSpeed() {
        for level in LevelDefinitions.levels {
            XCTAssertGreaterThan(level.baseSpeed, 0, "Level \(level.levelNumber) has zero base speed")
        }
    }

    func testLevels_LevelNumbersAreSequential() {
        for (index, level) in LevelDefinitions.levels.enumerated() {
            XCTAssertEqual(level.levelNumber, index + 1)
        }
    }
}
