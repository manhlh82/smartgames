import Foundation

struct CrosswordGameState: Codable {
    let puzzle: CrosswordPuzzle
    var boardState: CrosswordBoardState
    var elapsedSeconds: Int
    var hintsRemaining: Int
    var hintsUsedTotal: Int
    var undoStack: [CrosswordBoardSnapshot]
}
