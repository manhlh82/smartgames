import Foundation

/// Represents a single cell's mutable state during gameplay.
/// userEntry and solutionChar are stored as single-character strings for Codable compatibility.
struct CrosswordCellState: Codable {
    /// Letter the user has entered (nil = empty). Single character.
    var userEntryString: String?
    var isRevealed: Bool = false
    let isBlack: Bool
    let clueNumber: Int?
    /// Expected solution letter. nil for black cells.
    let solutionString: String?

    // MARK: - Computed Character accessors

    var userEntry: Character? {
        get { userEntryString.flatMap { $0.first } }
        set { userEntryString = newValue.map { String($0) } }
    }

    var solutionChar: Character? {
        solutionString?.first
    }
}

struct CrosswordBoardState: Codable {
    var cells: [[CrosswordCellState]]

    init(from puzzle: CrosswordPuzzle) {
        // Build clue number map (row,col -> clue number)
        var clueNumberMap: [String: Int] = [:]
        for clue in puzzle.clues {
            let key = "\(clue.startRow),\(clue.startCol)"
            if clueNumberMap[key] == nil {
                clueNumberMap[key] = clue.number
            }
        }
        cells = puzzle.grid.enumerated().map { row, rowArr in
            rowArr.enumerated().map { col, char in
                let isBlack = char == "#"
                let key = "\(row),\(col)"
                return CrosswordCellState(
                    userEntryString: nil,
                    isRevealed: false,
                    isBlack: isBlack,
                    clueNumber: clueNumberMap[key],
                    solutionString: isBlack ? nil : char.uppercased()
                )
            }
        }
    }
}

struct CrosswordBoardSnapshot: Codable {
    let cells: [[CrosswordCellState]]
}
