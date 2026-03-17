import SwiftUI

/// Game over screen — shows final score, high score badge, gold earned, and action buttons.
struct Stack2048GameOverOverlay: View {
    let score: Int
    let highScore: Int
    let isNewHighScore: Bool
    let goldEarned: Int
    let goldBalance: Int
    let diamondBalance: Int
    let isAdReady: Bool
    let onRetry: () -> Void
    let onQuit: () -> Void
    let onWatchAdContinue: () -> Void
    let onDiamondContinue: () -> Void

    @State private var showGoldBalance = false
    @State private var showGoldToast = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Game Over")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)

                // Score
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())

                    if isNewHighScore {
                        Label("New High Score!", systemImage: "trophy.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.orange)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("Best: \(highScore)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }

                // Gold balance
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.yellow)
                        .scaleEffect(showGoldBalance ? 1.0 : 0.3)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.3), value: showGoldBalance)
                    Text("\(goldBalance) Gold")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .opacity(showGoldBalance ? 1.0 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: showGoldBalance)
                    if goldEarned > 0 {
                        Text("+\(goldEarned)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.green)
                            .opacity(showGoldBalance ? 1.0 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.5), value: showGoldBalance)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(Color.yellow.opacity(0.12))
                .clipShape(Capsule())

                // Continue options (two-column death popup)
                DeathPopupView(
                    isAdReady: isAdReady,
                    diamondBalance: diamondBalance,
                    diamondCost: DiamondReward.continueFullReviveCost,
                    onWatchAd: onWatchAdContinue,
                    onDiamonds: onDiamondContinue
                )

                // Action buttons
                VStack(spacing: 10) {
                    Button(action: onRetry) {
                        Label("Play Again", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button(action: onQuit) {
                        Text("Back to Hub")
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
            .onAppear {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    showGoldBalance = true
                    if goldEarned > 0 { showGoldToast = true }
                }
            }

            // Gold reward toast
            if showGoldToast && goldEarned > 0 {
                GoldRewardToast(amount: goldEarned)
                    .padding(.top, 16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showGoldToast)
    }
}
