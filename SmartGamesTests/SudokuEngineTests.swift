import XCTest
@testable import SmartGames

// MARK: - Solver Tests

final class SudokuSolverTests: XCTestCase {
    var solver: SudokuSolver!

    override func setUp() {
        super.setUp()
        solver = SudokuSolver()
    }

    // A well-known easy puzzle (0 = empty cell)
    private let knownPuzzle: [[Int]] = [
        [5,3,0,0,7,0,0,0,0],
        [6,0,0,1,9,5,0,0,0],
        [0,9,8,0,0,0,0,6,0],
        [8,0,0,0,6,0,0,0,3],
        [4,0,0,8,0,3,0,0,1],
        [7,0,0,0,2,0,0,0,6],
        [0,6,0,0,0,0,2,8,0],
        [0,0,0,4,1,9,0,0,5],
        [0,0,0,0,8,0,0,7,9]
    ]

    func testSolveKnownPuzzle_ReturnsSolution() {
        let solution = solver.solve(knownPuzzle)
        XCTAssertNotNil(solution)
        XCTAssertTrue(solution?.flatMap { $0 }.allSatisfy { $0 != 0 } == true)
    }

    func testCountSolutions_KnownUniquePuzzle_ReturnsOne() {
        XCTAssertEqual(solver.countSolutions(knownPuzzle, limit: 2), 1)
    }

    func testCountSolutions_EmptyBoard_HitsLimit() {
        let empty = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        // Empty board has millions of solutions; we just verify it hits the limit of 2
        XCTAssertEqual(solver.countSolutions(empty, limit: 2), 2)
    }

    func testSolve_InvalidBoard_ReturnsNil() {
        // Row 0 has two 5s — unsolvable
        var invalid = knownPuzzle
        invalid[0][1] = 5
        XCTAssertNil(solver.solve(invalid))
    }
}

// MARK: - Validator Tests

final class SudokuValidatorTests: XCTestCase {
    var validator: SudokuValidator!

    override func setUp() {
        super.setUp()
        validator = SudokuValidator()
    }

    func testIsValidPlacement_NoConflict_ReturnsTrue() {
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        board[0][0] = 5
        XCTAssertTrue(validator.isValidPlacement(value: 3, row: 0, col: 1, board: board))
    }

    func testIsValidPlacement_RowConflict_ReturnsFalse() {
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        board[0][0] = 5
        XCTAssertFalse(validator.isValidPlacement(value: 5, row: 0, col: 1, board: board))
    }

    func testIsValidPlacement_BoxConflict_ReturnsFalse() {
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        board[0][0] = 5
        XCTAssertFalse(validator.isValidPlacement(value: 5, row: 1, col: 1, board: board))
    }

    func testIsValidPlacement_ColConflict_ReturnsFalse() {
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        board[0][0] = 5
        XCTAssertFalse(validator.isValidPlacement(value: 5, row: 1, col: 0, board: board))
    }

    func testCandidates_RowAlmostFull_ReturnsSingleValue() {
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        for c in 0..<8 { board[0][c] = c + 1 } // fill 1-8 in row 0
        let result = validator.candidates(row: 0, col: 8, board: board)
        XCTAssertEqual(result, [9])
    }

    func testIsSolved_CompletedBoard_ReturnsTrue() {
        let solution: [[Int]] = [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
        ]
        let board: [[SudokuCell]] = solution.enumerated().map { (r, row) in
            row.enumerated().map { (c, v) in
                SudokuCell(row: r, col: c, value: v, isGiven: true)
            }
        }
        XCTAssertTrue(validator.isSolved(board, solution: solution))
    }

    func testFindErrors_IncorrectCell_ReturnsPosition() {
        let solution: [[Int]] = Array(repeating: Array(repeating: 1, count: 9), count: 9)
        var board: [[SudokuCell]] = solution.enumerated().map { (r, row) in
            row.enumerated().map { (c, v) in SudokuCell(row: r, col: c, value: v, isGiven: false) }
        }
        board[3][4].value = 9 // deliberate wrong value (expected 1)
        let errors = validator.findErrors(board, solution: solution)
        XCTAssertTrue(errors.contains(CellPosition(row: 3, col: 4)))
    }
}

// MARK: - Generator Tests

final class SudokuGeneratorTests: XCTestCase {
    var generator: SudokuGenerator!
    var solver: SudokuSolver!

    override func setUp() {
        super.setUp()
        generator = SudokuGenerator()
        solver = SudokuSolver()
    }

    func testGenerateEasy_GivenCountInExpectedRange() {
        let puzzle = generator.generate(difficulty: .easy)
        let givenCount = puzzle.givens.flatMap { $0 }.filter { $0 != 0 }.count
        // Target is 40; allow ±8 tolerance for the uniqueness removal pass
        XCTAssertTrue((32...48).contains(givenCount),
                      "Easy given count \(givenCount) outside expected range 32-48")
    }

    func testGenerateMedium_HasUniqueSolution() {
        let puzzle = generator.generate(difficulty: .medium)
        XCTAssertEqual(solver.countSolutions(puzzle.givens, limit: 2), 1)
    }

    func testGenerateHard_HasUniqueSolution() {
        let puzzle = generator.generate(difficulty: .hard)
        XCTAssertEqual(solver.countSolutions(puzzle.givens, limit: 2), 1,
                       "Hard puzzle must have exactly 1 solution")
    }

    func testGeneratePuzzle_SolverMatchesStoredSolution() {
        let puzzle = generator.generate(difficulty: .easy)
        let solved = solver.solve(puzzle.givens)
        XCTAssertEqual(solved, puzzle.solution)
    }

    func testGeneratedPuzzle_ModelBuildsCorrectly() {
        let puzzle = generator.generate(difficulty: .medium)
        // Board should have same number of empty cells as givens grid
        XCTAssertEqual(puzzle.emptyCellCount, puzzle.totalEmptyCells)
    }
}

// MARK: - BoardUtils Tests

final class SudokuBoardUtilsTests: XCTestCase {

    func testCandidates_EmptyCell_ReturnsAllNine() {
        let empty = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        let result = SudokuBoardUtils.candidates(row: 0, col: 0, in: empty)
        XCTAssertEqual(result, Set(1...9))
    }

    func testCandidates_FilledCell_ReturnsEmpty() {
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        board[0][0] = 5
        let result = SudokuBoardUtils.candidates(row: 0, col: 0, in: board)
        XCTAssertTrue(result.isEmpty)
    }

    func testBoxIndices_TopLeft_ReturnsNineCells() {
        let indices = SudokuBoardUtils.boxIndices(for: 0, col: 0)
        XCTAssertEqual(indices.count, 9)
        XCTAssertTrue(indices.allSatisfy { $0.0 < 3 && $0.1 < 3 })
    }

    func testPeers_Count_Is20() {
        // Any cell has 8 row peers + 8 col peers + 8 box peers - 4 overlaps = 20
        let peers = SudokuBoardUtils.peers(for: 4, col: 4)
        XCTAssertEqual(peers.count, 20)
    }
}
