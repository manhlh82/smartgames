import SwiftUI

/// Two-column continue popup used on game-over screens.
/// Left: Watch Ad (1 heart) — Right: Diamonds (full revive, highlighted).
struct DeathPopupView: View {
    let isAdReady: Bool
    let diamondBalance: Int
    let diamondCost: Int
    let onWatchAd: () -> Void
    let onDiamonds: () -> Void

    private var canAffordDiamonds: Bool { diamondBalance >= diamondCost }

    var body: some View {
        VStack(spacing: 10) {
            Text("Continue?")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                // Left: Watch Ad — secondary
                Button(action: onWatchAd) {
                    VStack(spacing: 5) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.orange)
                        Text("Watch Ad")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("1 heart")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isAdReady)
                .opacity(isAdReady ? 1.0 : 0.45)

                // Right: Diamonds — highlighted
                Button(action: onDiamonds) {
                    VStack(spacing: 5) {
                        HStack(spacing: 3) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                            Text("\(diamondCost)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text("Full Revive")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("\(diamondBalance) owned")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(
                        LinearGradient(
                            colors: canAffordDiamonds
                                ? [Color.cyan.opacity(0.85), Color.blue.opacity(0.85)]
                                : [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(canAffordDiamonds ? Color.cyan.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )
                    .shadow(color: canAffordDiamonds ? Color.cyan.opacity(0.3) : .clear, radius: 6)
                }
                .buttonStyle(.plain)
                .disabled(!canAffordDiamonds)
            }
        }
    }
}
