import Foundation

/// A single tile in the Stack 2048 grid.
/// Value is always a power of 2 (2, 4, 8 … 2048, 4096, …).
struct Stack2048Tile: Identifiable, Equatable, Codable {
    let id: UUID
    var value: Int
    /// Set true when this tile was just created by a merge — triggers scale-pulse animation.
    /// Reset to false at the start of the next drop.
    var isMergedThisTurn: Bool = false

    init(value: Int) {
        self.id = UUID()
        self.value = value
    }
}
