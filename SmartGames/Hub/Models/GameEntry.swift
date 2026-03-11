import SwiftUI

/// Metadata for a single game shown on the hub screen.
struct GameEntry: Identifiable {
    let id: String
    let displayName: String
    let iconName: String
    let isAvailable: Bool
}
