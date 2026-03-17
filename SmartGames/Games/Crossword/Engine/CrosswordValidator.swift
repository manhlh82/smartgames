import Foundation

/// Pure logic validator — no SwiftUI imports.
struct CrosswordValidator {
    func isSolved(board: CrosswordBoardState, puzzle: CrosswordPuzzle) -> Bool {
        for row in 0..<puzzle.size {
            for col in 0..<puzzle.size {
                let cell = board.cells[row][col]
                guard !cell.isBlack else { continue }
                guard let solution = cell.solutionChar,
                      let entry = cell.userEntry,
                      entry == solution else { return false }
            }
        }
        return true
    }

    func isLetterCorrect(row: Int, col: Int, board: CrosswordBoardState, puzzle: CrosswordPuzzle) -> Bool {
        let cell = board.cells[row][col]
        guard !cell.isBlack,
              let solution = cell.solutionChar,
              let entry = cell.userEntry else { return false }
        return entry == solution
    }

    func wordCells(for clue: CrosswordClue) -> [(row: Int, col: Int)] {
        (0..<clue.length).map { i in
            clue.direction == .across
                ? (row: clue.startRow, col: clue.startCol + i)
                : (row: clue.startRow + i, col: clue.startCol)
        }
    }
}
