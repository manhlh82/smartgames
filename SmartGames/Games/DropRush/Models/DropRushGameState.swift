import Foundation

/// Immutable snapshot of the engine's current state.
/// ViewModel reads this to drive UI updates.
struct EngineState {
    var fallingObjects: [FallingObject] = []
    var score: Int = 0
    var hits: Int = 0
    var misses: Int = 0           // objects that reached the ground
    var wrongTaps: Int = 0        // taps with no valid target
    var objectsSpawned: Int = 0
    var elapsedTime: TimeInterval = 0
    var livesRemaining: Int = 3
    var isComplete: Bool = false   // all objects spawned and cleared
    var isGameOver: Bool = false   // lives reached zero
    var currentSpeedMultiplier: CGFloat = 1.0
    // Combo tracking
    var comboCount: Int = 0
    var comboMultiplier: CGFloat = 1.0
    /// Tracks when each symbol last hit the ground (elapsedTime). Used for grace-period on wrong taps.
    var recentlyMissedSymbols: [String: TimeInterval] = [:]
}

/// Events emitted by the engine each tick or on tap.
/// ViewModel observes these to trigger SFX, haptics, and UI animations.
enum GameEvent {
    case objectSpawned(FallingObject)
    case objectDestroyed(id: UUID, symbol: String)   // successful tap hit
    case objectMissed(id: UUID, symbol: String)       // reached ground, life lost
    case wrongTap(symbol: String)                      // no matching target
    case objectDamaged(id: UUID, symbol: String)      // first hit on armored object — ring removed
    case speedPhaseChanged(multiplier: CGFloat)
    case levelComplete(score: Int, hits: Int, misses: Int)
    case gameOver
    case objectInDanger(id: UUID)                     // object normalizedY > 0.85
    case comboChanged(count: Int, multiplier: CGFloat)
}

/// Result returned immediately to the caller of handleTap(symbol:).
enum TapResult {
    /// Destroying hit — carries context needed for explosion animation.
    case hit(objectId: UUID, normalizedY: CGFloat, lane: Int, symbol: String)
    /// First hit on an armored object — ring removed, object stays on screen.
    case damaged(objectId: UUID)
    case noTarget
}
