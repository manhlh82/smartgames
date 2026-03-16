import SwiftUI

/// Transient data for a burst explosion animation shown on a successful tap.
/// Created by DropRushGameViewModel, consumed by HitEffectView.
struct HitEffect: Identifiable {
    let id = UUID()
    /// Normalized horizontal position (0–1) within the game area.
    let normalizedX: CGFloat
    /// Normalized vertical position (0–1) within the game area.
    let normalizedY: CGFloat
    /// Tint color matching the tapped symbol.
    let color: Color
}
