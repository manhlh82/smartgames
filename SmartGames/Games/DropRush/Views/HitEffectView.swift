import SwiftUI
import Foundation

/// Burst particle animation played at the position of a successfully tapped object.
/// 8 small circles expand outward and fade over 0.4 seconds.
struct HitEffectView: View {
    let effect: HitEffect
    let areaSize: CGSize

    /// Drives all animations — interpolated by SwiftUI via withAnimation.
    @State private var radius: CGFloat = 0
    @State private var opacity: Double = 0.85

    var body: some View {
        let x = effect.normalizedX * areaSize.width
        let y = effect.normalizedY * areaSize.height
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) / 8.0 * Double.pi * 2
                Circle()
                    .fill(effect.color.opacity(opacity))
                    .frame(width: 10, height: 10)
                    .offset(
                        x: CGFloat(Foundation.cos(angle)) * radius,
                        y: CGFloat(Foundation.sin(angle)) * radius
                    )
            }
        }
        .position(x: x, y: y)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                radius = 28
                opacity = 0
            }
        }
    }
}
