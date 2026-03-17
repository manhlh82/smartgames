import Foundation

/// The context in which a rewarded ad is requested.
/// Determines which outcome types are eligible.
enum AdContext: String {
    case goldReward     // Player explicitly watches for gold — subject to daily cap
    case `continue`     // Continue after game over (restore 1 heart)
    case undo           // Undo last move
}

/// The resolved reward granted after a successful rewarded-ad watch.
enum RewardedAdOutcome {
    case gold(Int)          // Gold amount — common; subject to daily cap
    case continueHeart(Int) // Restore N hearts — common
    case undo               // Free undo — context-specific
    case diamond(Int)       // Rare drop
}
