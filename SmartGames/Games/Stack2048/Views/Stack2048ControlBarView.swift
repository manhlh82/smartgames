import SwiftUI

/// Bottom action bar: Hammer | Shuffle | CurrentTile | AdButton.
struct Stack2048ControlBarView: View {
    let nextTile: Stack2048Tile
    let goldBalance: Int
    let phase: Stack2048Phase
    let isAdReady: Bool
    let onHammer: () -> Void
    let onShuffle: () -> Void
    let onCancelHammer: () -> Void
    let onRequestAd: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Hammer — enter hammer mode
            powerButton(
                icon: "hammer.fill",
                cost: 150,
                disabled: goldBalance < 150 || (phase != .playing && phase != .hammerMode),
                isActive: phase == .hammerMode,
                action: phase == .hammerMode ? onCancelHammer : onHammer
            )

            // Shuffle — replace next tile
            powerButton(
                icon: "arrow.2.squarepath",
                cost: 200,
                disabled: goldBalance < 200 || phase != .playing,
                isActive: false,
                action: onShuffle
            )

            // Current tile display (center, larger)
            currentTileDisplay

            // Ad button — earn +100 Gold
            adButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Subviews

    private func powerButton(
        icon: String,
        cost: Int,
        disabled: Bool,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isActive ? .red : .white)

                HStack(spacing: 2) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.cyan)
                    Text("\(cost)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(width: 58, height: 58)
            .background(isActive ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isActive ? Color.red.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
            .opacity(disabled ? 0.45 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var currentTileDisplay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Stack2048Colors.background(for: nextTile.value))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 2)
                )

            Text(nextTile.value >= 1000 ? "\(nextTile.value / 1000)K" : "\(nextTile.value)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 72, height: 72)
        .animation(.easeInOut(duration: 0.2), value: nextTile.value)
    }

    private var adButton: some View {
        Button(action: onRequestAd) {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.cyan)

                    Text("AD")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .clipShape(Capsule())
                        .offset(x: 12, y: -8)
                }
                .padding(.top, 8)

                Text("+100")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(width: 58, height: 58)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity((!isAdReady || phase != .playing) ? 0.45 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!isAdReady || phase != .playing)
    }
}
