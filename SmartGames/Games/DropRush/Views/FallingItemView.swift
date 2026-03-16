import SwiftUI

/// Color palette for Drop Rush symbols 1–9.
/// Consistent across FallingItemView and DropRushInputBarView.
enum DropRushColors {
    static let palette: [String: Color] = [
        "1": .red,
        "2": .orange,
        "3": .yellow,
        "4": .green,
        "5": .mint,
        "6": .cyan,
        "7": .blue,
        "8": .purple,
        "9": .pink,
    ]

    static func color(for symbol: String) -> Color {
        palette[symbol] ?? .gray
    }
}

/// A single falling object rendered in the game field.
/// Positioned absolutely using normalizedY × areaHeight and lane × laneWidth.
/// Shows a pulsing red border when in danger zone (normalizedY > 0.85).
/// Shows a rotating dashed white ring when armored (hitsRequired > 1 && hitsReceived == 0).
struct FallingItemView: View {
    let object: FallingObject
    let areaHeight: CGFloat
    let laneWidth: CGFloat

    @State private var ringRotation: Double = 0
    @State private var ringOpacity: Double = 0.6

    private var isDanger: Bool { object.normalizedY > 0.85 }
    /// Ring is only shown while the armor shield is intact (not yet hit).
    private var showArmorRing: Bool { object.hitsRequired > 1 && object.hitsReceived == 0 }

    /// Metallic gradient when fully armored; normal symbol color after first hit.
    private var digitBackground: AnyShapeStyle {
        if object.isArmored && object.hitsReceived == 0 {
            return AnyShapeStyle(LinearGradient(
                colors: [Color(white: 0.85), Color(white: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        }
        return AnyShapeStyle(DropRushColors.color(for: object.symbol))
    }

    /// Dark text on metallic background; white on colored background.
    private var digitForeground: Color {
        object.isArmored && object.hitsReceived == 0 ? Color(white: 0.15) : .white
    }

    /// Shadow color: grey when armored, symbol color otherwise.
    private var shadowColor: Color {
        object.isArmored && object.hitsReceived == 0
            ? Color.gray.opacity(0.5)
            : DropRushColors.color(for: object.symbol).opacity(0.4)
    }

    var body: some View {
        ZStack {
            // Digit circle
            Text(object.symbol)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .frame(width: 48, height: 48)
                .foregroundStyle(digitForeground)
                .animation(.easeOut(duration: 0.2), value: object.hitsReceived)
                .background(digitBackground)
                .animation(.easeOut(duration: 0.2), value: object.hitsReceived)
                .clipShape(Circle())
                .shadow(color: shadowColor, radius: 6, y: 3)
                .animation(.easeOut(duration: 0.2), value: object.hitsReceived)
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(isDanger ? 0.85 : 0), lineWidth: 3)
                        .animation(
                            isDanger
                                ? .easeInOut(duration: 0.3).repeatForever(autoreverses: true)
                                : .default,
                            value: isDanger
                        )
                )

            // Armored glow ring — rotating dashed white circle, removed after first hit
            if showArmorRing {
                armorRing
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: showArmorRing)
        .position(
            x: CGFloat(object.lane) * laneWidth + laneWidth / 2,
            y: object.normalizedY * areaHeight
        )
        .onAppear {
            guard showArmorRing else { return }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                ringOpacity = 1.0
            }
        }
    }

    // MARK: - Subviews

    private var armorRing: some View {
        Circle()
            .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
            .foregroundStyle(.white.opacity(ringOpacity))
            .frame(width: 58, height: 58)
            .shadow(color: .white.opacity(0.8), radius: 6)
            .rotationEffect(.degrees(ringRotation))
    }
}
