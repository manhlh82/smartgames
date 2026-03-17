import Foundation

/// Pure-logic game engine for Stack 2048.
/// Zero UIKit/SwiftUI imports — fully testable in isolation.
/// ViewModel drives it by calling dropTile(into:) on each player action.
final class Stack2048Engine {

    private(set) var state: Stack2048GameState

    init() {
        let first = Stack2048Engine.generateTile(boardMax: 0)
        self.state = Stack2048GameState(nextTile: first)
    }

    // MARK: - Player Actions

    /// Drop the current next tile into `column`. Returns events for the ViewModel to process.
    @discardableResult
    func dropTile(into column: Int) -> [Stack2048EngineEvent] {
        guard !state.isGameOver, state.canDrop(into: column) else { return [] }

        var events: [Stack2048EngineEvent] = []

        // Clear previous merge flags
        for col in 0..<Stack2048GameState.columnCount {
            for row in state.columns[col].indices {
                state.columns[col][row].isMergedThisTurn = false
            }
        }

        // Place tile at top of column (index 0)
        var placed = state.nextTile
        placed.isMergedThisTurn = false
        state.columns[column].insert(placed, at: 0)
        events.append(.tilePlaced(column: column))

        // Resolve chain merges from the top
        let mergeEvents = resolveMerges(in: column)
        events.append(contentsOf: mergeEvents)

        // Generate next tile
        state.nextTile = Stack2048Engine.generateTile(boardMax: state.maxTileValue)

        // Check game over
        if state.allColumnsFull {
            state.isGameOver = true
            events.append(.gameOver)
        }

        return events
    }

    /// Remove a tile at (column, row) — used by the Hammer power-up.
    /// Returns merge events if removal causes adjacent tiles to chain-merge.
    @discardableResult
    func removeTile(at column: Int, row: Int) -> [Stack2048EngineEvent] {
        guard column >= 0, column < Stack2048GameState.columnCount,
              row >= 0, row < state.columns[column].count else { return [] }

        state.columns[column].remove(at: row)

        // After removal, tiles shift — check merges from top
        return resolveMerges(in: column)
    }

    /// Replace the queued next tile with a different randomly generated one — Shuffle power-up.
    func replaceNextTile() {
        let current = state.nextTile.value
        var candidate = Stack2048Engine.generateTile(boardMax: state.maxTileValue)
        // Retry up to 5 times to get a different value
        for _ in 0..<5 where candidate.value == current {
            candidate = Stack2048Engine.generateTile(boardMax: state.maxTileValue)
        }
        state.nextTile = candidate
    }

    /// Reset to a fresh game.
    func reset() {
        let first = Stack2048Engine.generateTile(boardMax: 0)
        state = Stack2048GameState(nextTile: first)
    }

    /// Reset and pre-place challenge initial tiles at the bottom of their columns.
    func resetForChallenge(initialTiles: [(col: Int, value: Int)]) {
        reset()
        for tile in initialTiles {
            guard tile.col >= 0, tile.col < Stack2048GameState.columnCount else { continue }
            state.columns[tile.col].append(Stack2048Tile(value: tile.value))
        }
    }

    /// Place a single tile at the bottom of `column` (col index 0-based, bottom = end of array).
    func placeTileAtBottom(value: Int, column: Int) {
        guard column >= 0, column < Stack2048GameState.columnCount else { return }
        state.columns[column].append(Stack2048Tile(value: value))
    }

    /// Returns true if any tile on the board has reached `target` value.
    func hasReachedTargetTile(_ target: Int) -> Bool {
        state.columns.contains { $0.contains { $0.value >= target } }
    }

    // MARK: - Merge Logic

    /// Resolve chain merges from the top of `column`.
    /// tiles[0] is newest. Merges [0] with [1] if equal, then checks [0] with new [1], etc.
    private func resolveMerges(in column: Int) -> [Stack2048EngineEvent] {
        var events: [Stack2048EngineEvent] = []

        while state.columns[column].count >= 2 {
            let top = state.columns[column][0]
            let below = state.columns[column][1]

            guard top.value == below.value else { break }

            let mergedValue = top.value * 2
            state.score += mergedValue

            // Remove both, insert merged tile at top
            state.columns[column].removeFirst(2)
            var merged = Stack2048Tile(value: mergedValue)
            merged.isMergedThisTurn = true
            state.columns[column].insert(merged, at: 0)

            events.append(.tileMerged(column: column, row: 0, newValue: mergedValue))
        }

        return events
    }

    // MARK: - Tile Generation

    /// Weighted random tile spawn based on the highest tile currently on the board.
    static func generateTile(boardMax: Int) -> Stack2048Tile {
        let pool: [(value: Int, weight: Int)
        ]
        switch boardMax {
        case 0..<32:
            pool = [(2, 70), (4, 30)]
        case 32..<128:
            pool = [(2, 50), (4, 30), (8, 20)]
        case 128..<512:
            pool = [(2, 40), (4, 30), (8, 20), (16, 10)]
        default:
            pool = [(4, 30), (8, 30), (16, 25), (32, 15)]
        }

        let total = pool.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<total)
        for entry in pool {
            roll -= entry.weight
            if roll < 0 { return Stack2048Tile(value: entry.value) }
        }
        return Stack2048Tile(value: pool[0].value)
    }
}
