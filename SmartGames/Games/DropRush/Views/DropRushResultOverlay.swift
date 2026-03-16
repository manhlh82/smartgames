import SwiftUI

/// Win/loss result overlay shown when a level ends.
/// Displays star rating (win) or game-over message, score, high-score badge, and action buttons.
struct DropRushResultOverlay: View {
    let state: EngineState
    let stars: Int
    let isGameOver: Bool
    let isNewHighScore: Bool
    let continueAvailable: Bool
    let showPerfectAccuracy: Bool
    let levelNumber: Int
    /// Gold earned on level complete (0 for game over).
    let goldEarned: Int
    let onNextLevel: () -> Void
    let onRetry: () -> Void
    let onLobby: () -> Void
    let onContinue: () -> Void

    @State private var revealedStars: Int = 0
    @State private var starAnimTask: Task<Void, Never>?
    @State private var showGoldToast: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 20) {
                // Title
                Text(isGameOver ? "Game Over" : "Level Complete!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(isGameOver ? .red : .primary)

                // Stars (win only)
                if !isGameOver {
                    HStack(spacing: 12) {
                        ForEach(1...3, id: \.self) { i in
                            Image(systemName: i <= revealedStars ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundStyle(i <= revealedStars ? .yellow : .secondary.opacity(0.3))
                                .scaleEffect(i <= revealedStars ? 1.15 : 1.0)
                                .animation(.spring(duration: 0.4), value: revealedStars)
                        }
                    }
                    .onAppear {
                        animateStars()
                        if goldEarned > 0 {
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 800_000_000)
                                showGoldToast = true
                            }
                        }
                    }
                    .onDisappear { starAnimTask?.cancel() }
                }

                // Perfect accuracy badge (win only)
                if showPerfectAccuracy {
                    Label("PERFECT!", systemImage: "sparkles")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                }

                // Score
                VStack(spacing: 4) {
                    Text("\(state.score)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                    if isNewHighScore {
                        Label("New High Score!", systemImage: "trophy.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }

                // Accuracy
                let total = state.hits + state.misses
                if total > 0 {
                    let pct = Int(Double(state.hits) / Double(total) * 100)
                    Text("Accuracy: \(pct)%  ·  Hits: \(state.hits)  ·  Missed: \(state.misses)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                // Buttons
                VStack(spacing: 10) {
                    if !isGameOver {
                        Button(action: onNextLevel) {
                            Label("Next Level", systemImage: "arrow.right.circle.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }

                    if isGameOver && continueAvailable {
                        Button(action: onContinue) {
                            Label("Watch Ad to Continue", systemImage: "play.rectangle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: onRetry) {
                        Text(isGameOver ? "Try Again" : "Retry Level")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color(.secondarySystemBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button(action: onLobby) {
                        Text("Back to Lobby")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(28)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 24)
            .padding(.horizontal, 28)

            // Coin reward toast (level complete only)
            if showGoldToast && !isGameOver && goldEarned > 0 {
                GoldRewardToast(amount: goldEarned)
                    .padding(.top, 16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func animateStars() {
        starAnimTask?.cancel()
        starAnimTask = Task { @MainActor in
            for i in 1...3 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: UInt64(Double(i) * 0.35 * 1_000_000_000))
                guard !Task.isCancelled else { return }
                if i <= stars { revealedStars = i }
            }
        }
    }
}
