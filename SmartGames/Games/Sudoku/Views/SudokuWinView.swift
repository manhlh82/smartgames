import SwiftUI

/// Win screen shown modally on puzzle completion.
struct SudokuWinView: View {
    let elapsedSeconds: Int
    let mistakes: Int
    let stars: Int
    let difficulty: SudokuDifficulty
    let onNextPuzzle: () -> Void
    let onBackToMenu: () -> Void

    @EnvironmentObject private var gameCenterService: GameCenterService
    @State private var showStars: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Puzzle Solved!")
                .font(.appTitle)
                .foregroundColor(.appTextPrimary)

            // Star rating with entrance animation
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= stars ? "star.fill" : "star")
                        .font(.system(size: 36))
                        .foregroundColor(i <= stars ? .yellow : .gray.opacity(0.4))
                        .accessibilityLabel(i <= stars ? "Star awarded" : "Star not awarded")
                        .scaleEffect(showStars ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6)
                                .delay(Double(i) * 0.15),
                            value: showStars
                        )
                }
            }
            .onAppear { showStars = true }

            // Stats card
            VStack(spacing: 8) {
                statRow(icon: "clock", label: "Time", value: formatTime(elapsedSeconds))
                statRow(icon: "xmark.circle", label: "Mistakes",
                        value: "\(mistakes)/\(difficulty.mistakeLimit)")
            }
            .padding()
            .background(Color.appBackground)
            .cornerRadius(AppTheme.cardCornerRadius)

            // Actions
            VStack(spacing: 12) {
                PrimaryButton(title: "Next Puzzle", action: onNextPuzzle)
                Button("Back to Menu", action: onBackToMenu)
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .accessibilityLabel("Back to menu")
                if gameCenterService.isAuthenticated {
                    Button {
                        gameCenterService.showLeaderboard(for: difficulty)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trophy")
                            Text("View Leaderboard")
                        }
                        .font(.appBody)
                        .foregroundColor(.appAccent)
                    }
                    .accessibilityLabel("View \(difficulty.displayName) leaderboard")
                }
            }
        }
        .padding(AppTheme.standardPadding * 1.5)
        .background(Color.appCard)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
        .padding(AppTheme.standardPadding)
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.appTextSecondary)
            Text(label).font(.appBody).foregroundColor(.appTextSecondary)
            Spacer()
            Text(value).font(.appHeadline).foregroundColor(.appTextPrimary)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
