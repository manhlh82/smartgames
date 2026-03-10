import XCTest
@testable import SmartGames

final class SettingsServiceTests: XCTestCase {
    var persistence: PersistenceService!
    var sut: SettingsService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService()
        persistence.delete(key: PersistenceService.Keys.appSettings)
        sut = SettingsService(persistence: persistence)
    }

    override func tearDown() {
        persistence.delete(key: PersistenceService.Keys.appSettings)
        super.tearDown()
    }

    func testDefaultValues() {
        XCTAssertTrue(sut.isSoundEnabled)
        XCTAssertTrue(sut.isHapticsEnabled)
        XCTAssertTrue(sut.highlightRelatedCells)
        XCTAssertTrue(sut.highlightSameNumbers)
        XCTAssertTrue(sut.showTimer)
    }

    func testSettingsPersist() {
        sut.isSoundEnabled = false
        sut.isHapticsEnabled = false

        // Load fresh instance from same persistence
        let sut2 = SettingsService(persistence: persistence)
        XCTAssertFalse(sut2.isSoundEnabled)
        XCTAssertFalse(sut2.isHapticsEnabled)
        XCTAssertTrue(sut2.highlightRelatedCells) // unchanged
    }
}
