import XCTest
@testable import SmartGames

final class DropRushProgressTests: XCTestCase {

    // MARK: - recordResult

    func testRecordResult_SetsStarsAndScore() {
        var progress = DropRushProgress()
        progress.recordResult(level: 1, stars: 2, score: 500)
        XCTAssertEqual(progress.starsForLevel(1), 2)
        XCTAssertEqual(progress.levelHighScores[1], 500)
    }

    func testRecordResult_OnlyImprovesStars() {
        var progress = DropRushProgress()
        progress.recordResult(level: 1, stars: 3, score: 800)
        progress.recordResult(level: 1, stars: 1, score: 200)
        // Stars should not downgrade
        XCTAssertEqual(progress.starsForLevel(1), 3)
    }

    func testRecordResult_OnlyImprovesScore() {
        var progress = DropRushProgress()
        progress.recordResult(level: 1, stars: 2, score: 800)
        progress.recordResult(level: 1, stars: 2, score: 300)
        // Score should not downgrade
        XCTAssertEqual(progress.levelHighScores[1], 800)
    }

    func testRecordResult_UpdatesCumulativeOnImprovement() {
        var progress = DropRushProgress()
        progress.recordResult(level: 1, stars: 2, score: 500)
        XCTAssertEqual(progress.cumulativeHighScore, 500)
        progress.recordResult(level: 1, stars: 3, score: 700)
        // +200 delta improvement
        XCTAssertEqual(progress.cumulativeHighScore, 700)
    }

    func testRecordResult_MultipleLevels_AccumulatesCumulative() {
        var progress = DropRushProgress()
        progress.recordResult(level: 1, stars: 3, score: 500)
        progress.recordResult(level: 2, stars: 2, score: 300)
        XCTAssertEqual(progress.cumulativeHighScore, 800)
    }

    // MARK: - isUnlocked

    func testIsUnlocked_LevelOneAlwaysUnlocked() {
        let progress = DropRushProgress()
        XCTAssertTrue(progress.isUnlocked(1))
    }

    func testIsUnlocked_Level2LockedByDefault() {
        let progress = DropRushProgress()
        XCTAssertFalse(progress.isUnlocked(2))
    }

    func testIsUnlocked_Level2UnlockedAfterLevel1Star() {
        var progress = DropRushProgress()
        progress.recordResult(level: 1, stars: 1, score: 100)
        XCTAssertTrue(progress.isUnlocked(2))
    }

    // MARK: - totalStars

    func testTotalStars_SumsAllLevels() {
        var progress = DropRushProgress()
        progress.recordResult(level: 1, stars: 3, score: 100)
        progress.recordResult(level: 2, stars: 2, score: 100)
        progress.recordResult(level: 3, stars: 1, score: 100)
        XCTAssertEqual(progress.totalStars, 6)
    }

    // MARK: - starsForAccuracy (global helper)

    func testStarsForAccuracy_PerfectScore() {
        XCTAssertEqual(starsForAccuracy(hits: 20, misses: 0), 3)
    }

    func testStarsForAccuracy_HighAccuracy() {
        XCTAssertEqual(starsForAccuracy(hits: 16, misses: 2), 2) // ~88.9% → 2 stars (80%–95% range)
        XCTAssertEqual(starsForAccuracy(hits: 19, misses: 1), 3) // 95% → 3 stars
    }

    func testStarsForAccuracy_LowAccuracy() {
        XCTAssertEqual(starsForAccuracy(hits: 5, misses: 10), 0) // ~33% → 0 stars
    }

    func testStarsForAccuracy_NoObjects_ReturnsZero() {
        XCTAssertEqual(starsForAccuracy(hits: 0, misses: 0), 0)
    }
}
