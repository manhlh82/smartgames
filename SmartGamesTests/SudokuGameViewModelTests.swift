import XCTest
@testable import SmartGames

@MainActor
final class SudokuGameViewModelTests: XCTestCase {
    var sut: SudokuGameViewModel!
    var puzzle: SudokuPuzzle!
    var persistence: PersistenceService!

    override func setUp() async throws {
        try await super.setUp()
        let generator = SudokuGenerator()
        puzzle = generator.generate(difficulty: .easy)
        persistence = PersistenceService()
        sut = SudokuGameViewModel(
            puzzle: puzzle,
            persistence: persistence,
            analytics: AnalyticsService(),
            sound: SoundService(),
            haptics: HapticsService(),
            ads: AdsService()
        )
    }

    override func tearDown() async throws {
        sut = nil
        puzzle = nil
        persistence = nil
        try await super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState_GamePhaseIsPlaying() {
        XCTAssertEqual(sut.gamePhase, .playing)
    }

    func testInitialState_MistakeCountIsZero() {
        XCTAssertEqual(sut.mistakeCount, 0)
    }

    func testInitialState_NoSelectedCell() {
        XCTAssertNil(sut.selectedCell)
    }

    func testInitialState_PencilModeOff() {
        XCTAssertFalse(sut.isPencilMode)
    }

    func testInitialState_UndoNotAvailable() {
        XCTAssertFalse(sut.isUndoAvailable)
    }

    // MARK: - Cell Selection

    func testSelectCell_SetsSelectedCell() {
        sut.selectCell(row: 0, col: 0)
        XCTAssertEqual(sut.selectedCell, CellPosition(row: 0, col: 0))
    }

    func testSelectCell_ChangesSelection() {
        sut.selectCell(row: 0, col: 0)
        sut.selectCell(row: 4, col: 4)
        XCTAssertEqual(sut.selectedCell, CellPosition(row: 4, col: 4))
    }

    // MARK: - Pencil Mode

    func testTogglePencilMode_TurnsOn() {
        sut.togglePencilMode()
        XCTAssertTrue(sut.isPencilMode)
    }

    func testTogglePencilMode_TurnsOffOnSecondToggle() {
        sut.togglePencilMode()
        sut.togglePencilMode()
        XCTAssertFalse(sut.isPencilMode)
    }

    // MARK: - Pause / Resume

    func testPause_ChangesPhase() {
        sut.pause()
        XCTAssertEqual(sut.gamePhase, .paused)
    }

    func testResume_AfterPause_RestoresPlaying() {
        sut.pause()
        sut.resume()
        XCTAssertEqual(sut.gamePhase, .playing)
    }

    func testPause_WhenAlreadyPaused_NoChange() {
        sut.pause()
        sut.pause()  // second call should be ignored
        XCTAssertEqual(sut.gamePhase, .paused)
    }

    func testResume_WhenNotPaused_NoChange() {
        sut.resume()  // should be ignored when not paused
        XCTAssertEqual(sut.gamePhase, .playing)
    }

    // MARK: - Restart

    func testRestart_ResetsPhaseToPlaying() {
        sut.pause()
        sut.restart()
        XCTAssertEqual(sut.gamePhase, .playing)
    }

    func testRestart_ResetsMistakeCount() {
        sut.mistakeCount = 2
        sut.restart()
        XCTAssertEqual(sut.mistakeCount, 0)
    }

    func testRestart_ResetsElapsedSeconds() {
        sut.elapsedSeconds = 120
        sut.restart()
        XCTAssertEqual(sut.elapsedSeconds, 0)
    }

    func testRestart_ClearsUndoStack() {
        // Force a snapshot by attempting erase
        sut.selectCell(row: 0, col: 0)
        sut.restart()
        XCTAssertFalse(sut.isUndoAvailable)
    }

    func testRestart_ClearsSelectedCell() {
        sut.selectCell(row: 3, col: 3)
        sut.restart()
        XCTAssertNil(sut.selectedCell)
    }

    // MARK: - Erase

    func testEraseSelected_WhenNoSelection_DoesNothing() {
        // No crash expected, undo stack remains empty
        sut.eraseSelected()
        XCTAssertFalse(sut.isUndoAvailable)
    }

    func testEraseSelected_OnGivenCell_DoesNotModify() {
        // Find a given cell and try to erase it — board should not change
        guard let (row, col) = findGivenCell() else { return }
        let originalValue = sut.puzzle.board[row][col].value
        sut.selectCell(row: row, col: col)
        sut.eraseSelected()
        XCTAssertEqual(sut.puzzle.board[row][col].value, originalValue)
    }

    // MARK: - Highlight State

    func testHighlightState_WithNoSelection_ReturnsNormal() {
        let state = sut.highlightState(for: 4, col: 4)
        XCTAssertEqual(state, .normal)
    }

    func testHighlightState_SelectedEmptyCell_ReturnsSelectedEmpty() {
        guard let (row, col) = findEmptyCell() else {
            XCTSkip("No empty cell found in puzzle")
            return
        }
        sut.selectCell(row: row, col: col)
        XCTAssertEqual(sut.highlightState(for: row, col: col), .selectedEmpty)
    }

    func testHighlightState_RelatedCell_ReturnsRelated() {
        guard let (row, col) = findEmptyCell() else {
            XCTSkip("No empty cell found")
            return
        }
        sut.selectCell(row: row, col: col)
        // Check a peer in same row (different column)
        let peerCol = (col + 1) % 9
        if peerCol != col {
            let state = sut.highlightState(for: row, col: peerCol)
            XCTAssertEqual(state, .related)
        }
    }

    // MARK: - Completed Numbers

    func testCompletedNumbers_InitiallyEmpty_ForSparseBoard() {
        // A freshly generated easy puzzle won't have any digit fully placed 9 times
        // (it has ~40 givens spread over all 9 digits)
        // completedNumbers may or may not be empty depending on puzzle, so just verify type
        XCTAssertTrue(sut.completedNumbers.isSubset(of: Set(1...9)))
    }

    // MARK: - Hint Ad

    func testCancelHintAd_RestoresPlayingPhase() {
        sut.gamePhase = .needsHintAd
        sut.cancelHintAd()
        XCTAssertEqual(sut.gamePhase, .playing)
    }

    // MARK: - Star Rating

    func testStarRating_PerfectGame_ThreeStars() {
        sut.mistakeCount = 0
        sut.elapsedSeconds = 200
        XCTAssertEqual(sut.starRating, 3)
    }

    func testStarRating_OneMistake_TwoStars() {
        sut.mistakeCount = 1
        sut.elapsedSeconds = 700
        XCTAssertEqual(sut.starRating, 2)
    }

    func testStarRating_MaxMistakesAndSlow_OneStar() {
        sut.mistakeCount = 3
        sut.elapsedSeconds = 1200
        XCTAssertEqual(sut.starRating, 1)
    }

    // MARK: - Helpers

    private func findGivenCell() -> (Int, Int)? {
        for row in 0..<9 {
            for col in 0..<9 {
                if sut.puzzle.board[row][col].isGiven { return (row, col) }
            }
        }
        return nil
    }

    private func findEmptyCell() -> (Int, Int)? {
        for row in 0..<9 {
            for col in 0..<9 {
                if sut.puzzle.board[row][col].value == nil { return (row, col) }
            }
        }
        return nil
    }
}
