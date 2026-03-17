import Foundation

/// Immutable snapshot of the engine's current state.
/// ViewModel reads this to drive UI updates.
struct Stack2048GameState {
    /// columns[col][0] = top tile (newest), columns[col][last] = bottom tile (oldest).
    /// Tiles stack downward: new tiles are prepended at index 0.
    var columns: [[Stack2048Tile]]
    var score: Int = 0
    var nextTile: Stack2048Tile
    var isGameOver: Bool = false

    static let columnCount = 5
    static let maxRows = 10

    init(nextTile: Stack2048Tile) {
        self.columns = Array(repeating: [], count: Stack2048GameState.columnCount)
        self.nextTile = nextTile
    }

    /// True if placing a tile into `column` is allowed.
    func canDrop(into column: Int) -> Bool {
        guard column >= 0, column < Stack2048GameState.columnCount else { return false }
        return columns[column].count < Stack2048GameState.maxRows
    }

    /// True if no column can accept another tile.
    var allColumnsFull: Bool {
        columns.allSatisfy { $0.count >= Stack2048GameState.maxRows }
    }

    /// Highest tile value currently on the board (0 if empty).
    var maxTileValue: Int {
        columns.flatMap { $0 }.map { $0.value }.max() ?? 0
    }
}

/// Events emitted by the engine on each player action.
/// ViewModel observes these to trigger SFX, haptics, and animations.
enum Stack2048EngineEvent {
    case tilePlaced(column: Int)
    case tileMerged(column: Int, row: Int, newValue: Int)
    case gameOver
}
