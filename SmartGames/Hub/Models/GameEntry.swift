import SwiftUI

/// Metadata for a single game shown on the hub screen.
struct GameEntry: Identifiable {
    let id: String
    let displayName: String
    let iconAsset: String
    let isAvailable: Bool
    let route: AppRoute?

    init(id: String, displayName: String, iconAsset: String, isAvailable: Bool, route: AppRoute? = nil) {
        self.id = id
        self.displayName = displayName
        self.iconAsset = iconAsset
        self.isAvailable = isAvailable
        self.route = route
    }
}
