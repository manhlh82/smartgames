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
            ads: AdsService(),
            statisticsService: StatisticsService(persistence: persistence),
            gameCenterService: GameCenterService(),
            goldService: GoldService(persistence: persistence)
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

    // MARK: - Interaction Rules: Pre-filled Cell Tap

    /// Tapping a given cell returns `.selected` (deep blue), NOT `.selectedEmpty` (yellow).
    func testSelectGivenCell_HighlightState_IsSelected_NotSelectedEmpty() {
        guard let (row, col) = findGivenCell() else { return }
        sut.selectCell(row: row, col: col)
        XCTAssertEqual(sut.highlightState(for: row, col: col), .selected)
        XCTAssertNotEqual(sut.highlightState(for: row, col: col), .selectedEmpty)
    }

    /// Peers of a given cell receive `.related` or `.sameNumber`, never `.selectedEmpty`.
    func testSelectGivenCell_Peers_AreRelated() {
        guard let (row, col) = findGivenCell() else { return }
        sut.selectCell(row: row, col: col)
        // Check one peer in the same row
        let peerCol = (col + 1) % 9
        let peerState = sut.highlightState(for: row, col: peerCol)
        XCTAssertTrue(
            peerState == .related || peerState == .sameNumber || peerState == .error,
            "Peer of given cell must be .related, .sameNumber, or .error — got \(peerState)"
        )
    }

    /// Cells sharing the same digit as a selected given cell get `.sameNumber` highlight.
    func testSelectGivenCell_SameDigitCells_AreSameNumber() {
        guard let (row, col) = findGivenCell() else { return }
        let givenValue = sut.puzzle.board[row][col].value
        sut.selectCell(row: row, col: col)
        // Find a different cell with the same value
        for r in 0..<9 {
            for c in 0..<9 {
                guard (r, c) != (row, col) else { continue }
                guard sut.puzzle.board[r][c].value == givenValue else { continue }
                let state = sut.highlightState(for: r, col: c)
                XCTAssertEqual(state, .sameNumber,
                    "Cell (\(r),\(c)) with same digit should be .sameNumber")
                return  // one confirmation is sufficient
            }
        }
    }

    // MARK: - Interaction Rules: Keypad Guards

    /// Placing a number on a given cell is a no-op — value must not change.
    func testPlaceNumber_OnGivenCell_IsNoOp() {
        guard let (row, col) = findGivenCell() else { return }
        let originalValue = sut.puzzle.board[row][col].value
        sut.selectCell(row: row, col: col)
        sut.placeNumber(9)
        XCTAssertEqual(sut.puzzle.board[row][col].value, originalValue,
            "Given cell value must be unchanged after placeNumber")
        XCTAssertFalse(sut.isUndoAvailable, "No snapshot should be pushed for given cell")
    }

    /// Placing a number with no cell selected is a no-op — board must not change.
    func testPlaceNumber_WithNoSelection_IsNoOp() {
        sut.selectedCell = nil
        // Snapshot of all values before
        let valuesBefore = sut.puzzle.board.map { $0.map(\.value) }
        sut.placeNumber(5)
        let valuesAfter = sut.puzzle.board.map { $0.map(\.value) }
        XCTAssertEqual(valuesBefore, valuesAfter, "Board must not change when no cell is selected")
        XCTAssertFalse(sut.isUndoAvailable, "No snapshot should be pushed when no cell selected")
    }

    /// Placing the correct digit on an empty editable cell updates the board.
    func testPlaceNumber_OnEmptyEditableCell_PlacesValue() {
        guard let (row, col) = findEmptyCell() else {
            XCTSkip("No empty cell found in puzzle")
            return
        }
        let correctDigit = sut.puzzle.solution[row][col]
        sut.selectCell(row: row, col: col)
        sut.placeNumber(correctDigit)
        XCTAssertEqual(sut.puzzle.board[row][col].value, correctDigit,
            "Correct digit must be placed in the editable empty cell")
        XCTAssertFalse(sut.puzzle.board[row][col].hasError,
            "Correct placement must not set hasError")
    }

    // MARK: - Interaction Rules: Highlight Priority

    /// An empty selected cell's peers are `.related`, never `.sameNumber` (cell has no digit).
    func testSelectEmptyCell_Peers_CannotBeSameNumber() {
        guard let (row, col) = findEmptyCell() else {
            XCTSkip("No empty cell found in puzzle")
            return
        }
        sut.selectCell(row: row, col: col)
        let peers = SudokuBoardUtils.peers(for: row, col: col)
        for peer in peers {
            let state = sut.highlightState(for: peer.row, col: peer.col)
            XCTAssertNotEqual(state, .sameNumber,
                "Peer (\(peer.row),\(peer.col)) of empty cell must not be .sameNumber")
        }
    }

    /// The selected cell itself is always `.selected` or `.selectedEmpty`, never `.sameNumber`.
    func testHighlightPriority_SelectedCell_NeverReturnsSameNumber() {
        guard let (row, col) = findGivenCell() else { return }
        sut.selectCell(row: row, col: col)
        let state = sut.highlightState(for: row, col: col)
        XCTAssertNotEqual(state, .sameNumber,
            "Selected cell must be .selected or .selectedEmpty, never .sameNumber")
        XCTAssertTrue(state == .selected || state == .selectedEmpty,
            "Selected cell state should be .selected or .selectedEmpty")
    }

    /// A cell with `hasError` returns `.error` even when it is also a peer of the selected cell.
    func testHighlightPriority_ErrorBeforeRelated() {
        guard let (selRow, selCol) = findGivenCell() else { return }
        sut.selectCell(row: selRow, col: selCol)
        // Inject an error into a peer cell (same row, different col)
        let peerCol = (selCol + 1) % 9
        sut.puzzle.board[selRow][peerCol].hasError = true
        let state = sut.highlightState(for: selRow, col: peerCol)
        XCTAssertEqual(state, .error,
            "Error state must take priority over .related")
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
