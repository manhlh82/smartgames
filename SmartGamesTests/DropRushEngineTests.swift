import XCTest
@testable import SmartGames

final class DropRushEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeEngine(totalObjects: Int = 10) -> DropRushEngine {
        let config = LevelConfig(
            levelNumber: 1,
            symbolPool: ["🍎", "🍊", "🍋"],
            baseSpeed: 0.5,
            spawnInterval: 0.5,
            maxOnScreen: 3,
            totalObjects: totalObjects,
            speedPhases: []
        )
        return DropRushEngine(config: config)
    }

    // MARK: - Tick

    func testTick_MovesObjectsDown() {
        let engine = makeEngine()
        _ = engine.tick(deltaTime: 1.0)
        _ = engine.tick(deltaTime: 1.0)
        guard let before = engine.state.fallingObjects.first?.normalizedY else { return }
        _ = engine.tick(deltaTime: 0.1)
        guard let after = engine.state.fallingObjects.first?.normalizedY else { return }
        XCTAssertGreaterThan(after, before)
    }

    func testTick_DoesNothingWhenGameOver() {
        let engine = makeEngine()
        engine.state.isGameOver = true
        let events = engine.tick(deltaTime: 1.0)
        XCTAssertTrue(events.isEmpty)
    }

    func testTick_DecreasesLivesOnMiss() {
        let engine = makeEngine()
        _ = engine.tick(deltaTime: 0.5)
        guard !engine.state.fallingObjects.isEmpty else { return }
        for i in engine.state.fallingObjects.indices {
            engine.state.fallingObjects[i].normalizedY = 1.1
        }
        let initialLives = engine.state.livesRemaining
        let events = engine.tick(deltaTime: 0.0)
        XCTAssertLessThan(engine.state.livesRemaining, initialLives)
        XCTAssertTrue(events.contains(where: {
            if case .objectMissed = $0 { return true }
            return false
        }))
    }

    func testTick_GameOverWhenNoLivesRemain() {
        let engine = makeEngine()
        _ = engine.tick(deltaTime: 0.5)
        guard !engine.state.fallingObjects.isEmpty else { return }
        engine.state.livesRemaining = 1
        for i in engine.state.fallingObjects.indices {
            engine.state.fallingObjects[i].normalizedY = 1.1
        }
        let events = engine.tick(deltaTime: 0.0)
        XCTAssertTrue(engine.state.isGameOver || events.contains(where: {
            if case .gameOver = $0 { return true }
            return false
        }))
    }

    // MARK: - HandleTap

    func testHandleTap_HitMatchingSymbol() {
        let engine = makeEngine()
        _ = engine.tick(deltaTime: 0.5)
        guard let target = engine.state.fallingObjects.first else { return }
        let result = engine.handleTap(symbol: target.symbol)
        if case .hit(_, _, _, _) = result { /* success */ } else { XCTFail("Expected hit") }
    }

    func testHandleTap_NoTargetForUnknownSymbol() {
        let engine = makeEngine()
        _ = engine.tick(deltaTime: 0.5)
        let result = engine.handleTap(symbol: "❌")
        if case .noTarget = result { /* success */ } else { XCTFail("Expected noTarget") }
    }

    func testHandleTap_IncreasesScore() {
        let engine = makeEngine()
        _ = engine.tick(deltaTime: 0.5)
        guard let target = engine.state.fallingObjects.first else { return }
        engine.handleTap(symbol: target.symbol)
        XCTAssertGreaterThan(engine.state.score, 0)
    }

    func testHandleTap_RemovesObjectFromField() {
        let engine = makeEngine()
        _ = engine.tick(deltaTime: 0.5)
        guard let target = engine.state.fallingObjects.first else { return }
        let countBefore = engine.state.fallingObjects.count
        engine.handleTap(symbol: target.symbol)
        XCTAssertEqual(engine.state.fallingObjects.count, countBefore - 1)
    }

    // MARK: - Reset / RestoreLife

    func testReset_ClearsState() {
        let engine = makeEngine()
        _ = engine.tick(deltaTime: 1.0)
        engine.reset()
        XCTAssertEqual(engine.state.score, 0)
        XCTAssertEqual(engine.state.hits, 0)
        XCTAssertTrue(engine.state.fallingObjects.isEmpty)
    }

    func testRestoreLife_AddsOneLife() {
        let engine = makeEngine()
        engine.state.livesRemaining = 0
        engine.state.isGameOver = true
        engine.restoreLife()
        XCTAssertEqual(engine.state.livesRemaining, 1)
        XCTAssertFalse(engine.state.isGameOver)
    }
}
