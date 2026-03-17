import SwiftUI

struct CrosswordWinView: View {
    let elapsedSeconds: Int
    let hintsUsed: Int
    let stars: Int
    let hintsGranted: Int
    let goldEarned: Int
    let onNextPuzzle: () -> Void
    let onBackToMenu: () -> Void

    @State private var showStars = false
    @State private var showGoldToast = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 24) {
                Text("Puzzle Solved!")
                    .font(.appTitle)
                    .foregroundColor(.appTextPrimary)

                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= stars ? "star.fill" : "star")
                            .font(.system(size: 36))
                            .foregroundColor(i <= stars ? .yellow : .gray.opacity(0.4))
                            .scaleEffect(showStars ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.6)
                                    .delay(Double(i) * 0.15),
                                value: showStars
                            )
                    }
                }
                .onAppear {
                    showStars = true
                    if goldEarned > 0 {
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 600_000_000)
                            showGoldToast = true
                        }
                    }
                }

                VStack(spacing: 8) {
                    statRow(icon: "clock", label: "Time", value: formatTime(elapsedSeconds))
                    statRow(icon: "lightbulb", label: "Hints Used", value: "\(hintsUsed)")
                    Divider()
                    if hintsGranted > 0 {
                        statRow(icon: "lightbulb.fill", label: "Hint Earned", value: "+\(hintsGranted)")
                            .foregroundColor(.yellow)
                    }
                }
                .padding()
                .background(Color.appBackground)
                .cornerRadius(AppTheme.cardCornerRadius)

                VStack(spacing: 12) {
                    PrimaryButton(title: "Next Puzzle", action: onNextPuzzle)
                    Button("Back to Menu", action: onBackToMenu)
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(AppTheme.standardPadding * 1.5)
            .background(Color.appCard)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
            .padding(AppTheme.standardPadding)

            if showGoldToast && goldEarned > 0 {
                GoldRewardToast(amount: goldEarned)
                    .padding(.top, 12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
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
