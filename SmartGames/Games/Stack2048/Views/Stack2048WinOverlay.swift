import SwiftUI

/// Shown when player first creates a 2048 tile. Offers Keep Playing or New Game.
struct Stack2048WinOverlay: View {
    let score: Int
    let goldEarned: Int
    let goldBalance: Int
    let onKeepPlaying: () -> Void
    let onNewGame: () -> Void

    @State private var trophyScale: CGFloat = 0.3

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.96, green: 0.82, blue: 0.15),
                                     Color(red: 0.91, green: 0.55, blue: 0.09)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .scaleEffect(trophyScale)

                Text("You reached 2048!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.96, green: 0.75, blue: 0.25),
                                     Color(red: 0.91, green: 0.55, blue: 0.09)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                Text("\(score)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

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

                VStack(spacing: 10) {
                    Button(action: onKeepPlaying) {
                        Text("Keep Playing")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button(action: onNewGame) {
                        Text("New Game")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
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
        }
    }
}
