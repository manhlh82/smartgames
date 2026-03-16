import Foundation

/// A single falling item in the game field.
/// normalizedY: 0.0 = top of field, 1.0 = ground (triggers miss).
/// Lane distributes objects horizontally across the play area.
/// hitsRequired == 2 means the object is "armored" and needs two correct taps.
struct FallingObject: Identifiable, Equatable {
    let id: UUID
    let symbol: String       // "1"–"9", or letter for later levels
    var normalizedY: CGFloat // 0.0 (top) → 1.0 (ground)
    let lane: Int            // horizontal position index (0..<laneCount)
    let speed: CGFloat       // normalized units per second (pre-multiplier base speed)
    let hitsRequired: Int    // 1 = normal, 2 = armored
    var hitsReceived: Int    // 0 = untouched, 1 = first hit taken (armored only)

    /// True when object needs 2 taps (has a glowing ring visual).
    var isArmored: Bool { hitsRequired > 1 }

    /// True when the next correct tap will destroy this object.
    var isVulnerable: Bool { hitsReceived >= hitsRequired - 1 }

    init(symbol: String, lane: Int, speed: CGFloat, hitsRequired: Int = 1) {
        self.id = UUID()
        self.symbol = symbol
        self.normalizedY = 0.0
        self.lane = lane
        self.speed = speed
        self.hitsRequired = hitsRequired
        self.hitsReceived = 0
    }
}
