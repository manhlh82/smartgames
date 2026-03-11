import SwiftUI

/// Full-screen view for the daily Sudoku challenge.
/// Shows today's difficulty, streak, and either a Play button or Completed state.
struct DailyChallengeView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var dailyChallenge: DailyChallengeService

    // Services forwarded to SudokuGameView when navigating
    let persistence: PersistenceService
    let analytics: AnalyticsService
    let sound: SoundService
    let haptics: HapticsService
    let ads: AdsService
    let statistics: StatisticsService
    let gameCenter: GameCenterService

    @State private var isLoading = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()
                headerSection
                streakSection
                difficultyBadge
                actionSection
                Spacer()
            }
            .padding(.horizontal, AppTheme.standardPadding)

            if isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Daily Challenge")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Daily Challenge")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.appTextPrimary)
            Text(formattedToday)
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
        }
    }

    private var streakSection: some View {
        HStack(spacing: 24) {
            streakStat(
                value: dailyChallenge.streak.currentStreak,
                label: "Current Streak",
                icon: "flame.fill",
                color: .orange
            )
            Divider().frame(height: 48)
            streakStat(
                value: dailyChallenge.streak.bestStreak,
                label: "Best Streak",
                icon: "star.fill",
                color: .yellow
            )
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(AppTheme.cardCornerRadius)
        .shadow(color: .black.opacity(0.08), radius: AppTheme.cardShadowRadius, x: 0, y: 2)
    }

    private func streakStat(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundColor(color)
                Text("\(value)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appTextPrimary)
            }
            Text(label)
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
        }
    }

    private var difficultyBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "puzzlepiece.fill").foregroundColor(.appTextSecondary)
            Text("Today: \(dailyChallenge.todayDifficulty().displayName)")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        if dailyChallenge.isCompletedToday() {
            completedState
        } else {
            playButton
        }
    }

    private var playButton: some View {
        Button(action: startDailyChallenge) {
            Text("Play Today's Puzzle")
                .font(.appHeadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(AppTheme.cardCornerRadius)
        }
        .accessibilityLabel("Play today's daily challenge")
    }

    private var completedState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Completed!")
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)
            }
            if let secs = dailyChallenge.todayState.elapsedSeconds {
                Text("Time: \(formattedTime(secs))")
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
            }
            if let stars = dailyChallenge.todayState.stars {
                starsView(count: stars)
            }
            Text("Come back tomorrow for a new puzzle!")
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(AppTheme.cardCornerRadius)
        .shadow(color: .black.opacity(0.08), radius: AppTheme.cardShadowRadius, x: 0, y: 2)
    }

    private func starsView(count: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { i in
                Image(systemName: i <= count ? "star.fill" : "star")
                    .foregroundColor(i <= count ? .yellow : .gray.opacity(0.4))
            }
        }
    }

    private var loadingOverlay: some View {
        Color.black.opacity(0.2)
            .ignoresSafeArea()
            .overlay(ProgressView().scaleEffect(1.5))
    }

    // MARK: - Actions

    private func startDailyChallenge() {
        isLoading = true
        Task {
            let puzzle = dailyChallenge.todayPuzzle()
            persistence.save(puzzle, key: PersistenceService.Keys.sudokuPendingPuzzle)
            // Flag this pending puzzle as a daily challenge so the game view
            // can wire DailyChallengeService into SudokuGameViewModel.
            persistence.save(true, key: PersistenceService.Keys.sudokuPendingIsDailyChallenge)
            isLoading = false
            router.navigate(to: .sudokuGame(difficulty: puzzle.difficulty))
        }
    }

    // MARK: - Helpers

    private var formattedToday: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        fmt.timeStyle = .none
        return fmt.string(from: Date())
    }

    private func formattedTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private extension View {
    func cornerRadius(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
