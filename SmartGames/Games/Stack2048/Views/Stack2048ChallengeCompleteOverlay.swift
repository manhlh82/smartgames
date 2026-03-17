import SwiftUI

/// Overlay shown when a challenge level is completed. Displays stars earned, gold, and action buttons.
struct Stack2048ChallengeCompleteOverlay: View {
    let stars: Int
    let goldEarned: Int
    let goldBalance: Int
    let levelNumber: Int
    let onNextLevel: () -> Void
    let onRetry: () -> Void
    let onQuit: () -> Void

    @State private var trophyScale: CGFloat = 0.3
    @State private var starsVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 20) {
                // Icon
                Image(systemName: stars == 3 ? "trophy.fill" : "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(iconGradient)
                    .scaleEffect(trophyScale)

                // Title
                Text(stars == 3 ? "Perfect!" : "Level Complete!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                // Stars
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= stars ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundStyle(i <= stars
                                ? Color(red: 0.91, green: 0.66, blue: 0.09)
                                : Color.secondary.opacity(0.3))
                            .scaleEffect(starsVisible && i <= stars ? 1.0 : 0.5)
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.55)
                                    .delay(Double(i) * 0.12),
                                value: starsVisible
                            )
                    }
                }

                // Gold earned
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.yellow)
                    Text("\(goldBalance) Gold")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("+\(goldEarned)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(Color.yellow.opacity(0.12))
                .clipShape(Capsule())

                // Action buttons
                VStack(spacing: 10) {
                    Button(action: onNextLevel) {
                        Text("Next Level")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.91, green: 0.66, blue: 0.09),
                                             Color(red: 0.96, green: 0.47, blue: 0.23)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 24) {
                        Button(action: onRetry) {
                            Text("Retry")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)

                        Button(action: onQuit) {
                            Text("Quit")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(28)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 24)
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                trophyScale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                starsVisible = true
            }
        }
    }

    private var iconGradient: some ShapeStyle {
        LinearGradient(
            colors: [Color(red: 0.96, green: 0.82, blue: 0.15),
                     Color(red: 0.91, green: 0.55, blue: 0.09)],
            startPoint: .top, endPoint: .bottom
        )
    }
}
