import SwiftUI

/// Sudoku game entry point — difficulty selection and optional resume.
struct SudokuLobbyView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var analytics: AnalyticsService
    @EnvironmentObject private var sound: SoundService
    @EnvironmentObject private var haptics: HapticsService
    @EnvironmentObject private var ads: AdsService
    @EnvironmentObject private var gameCenterService: GameCenterService
    @EnvironmentObject private var dailyChallenge: DailyChallengeService
    @EnvironmentObject private var themeService: ThemeService

    @StateObject private var viewModel: SudokuLobbyViewModel
    private let persistence: PersistenceService
    @State private var isLoadingGame = false
    @State private var showThemePicker = false

    init(persistence: PersistenceService) {
        self.persistence = persistence
        _viewModel = StateObject(wrappedValue: SudokuLobbyViewModel(persistence: persistence))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                titleSection
                    .padding(.bottom, 16)

                dailyChallengeCard
                    .padding(.horizontal, AppTheme.standardPadding)
                    .padding(.bottom, 16)

                if viewModel.hasSavedGame, let diff = viewModel.savedGameDifficulty {
                    resumeCard(difficulty: diff)
                        .padding(.horizontal, AppTheme.standardPadding)
                        .padding(.bottom, 16)
                }

                difficultySheet
            }
        }
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    if gameCenterService.isAuthenticated {
                        Button {
                            gameCenterService.showLeaderboard()
                        } label: {
                            Image(systemName: "trophy")
                                .foregroundColor(.appTextPrimary)
                        }
                        .accessibilityLabel("View leaderboards")
                    }
                    Button {
                        router.navigate(to: .gamePlay(gameId: "sudoku", context: "statistics"))
                    } label: {
                        Image(systemName: "chart.bar")
                            .foregroundColor(.appTextPrimary)
                    }
                    .accessibilityLabel("View statistics")
                    Button {
                        showThemePicker = true
                    } label: {
                        Image(systemName: "paintpalette")
                            .foregroundColor(.appTextPrimary)
                    }
                    .accessibilityLabel("Change board theme")
                }
            }
        }
        .sheet(isPresented: $showThemePicker) {
            boardThemeSheet
        }
        .overlay {
            if isLoadingGame {
                loadingOverlay
            }
        }
        .onAppear {
            analytics.log(.sudokuLobbyViewed)
            viewModel.checkForSavedGame()
        }
    }

    // MARK: - Subviews

    /// Sheet presented when the user taps the palette toolbar button.
    private var boardThemeSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pick a color theme for the Sudoku board.")
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .padding(.horizontal)
                ThemePickerView()
                    .padding(.horizontal)
                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Board Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showThemePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text("Sudoku")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.appTextPrimary)
            Text("Unlock your brain.")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
        }
    }

    private func resumeCard(difficulty: SudokuDifficulty) -> some View {
        VStack(spacing: 8) {
            Text("Resume \(difficulty.displayName)")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
            HStack(spacing: 12) {
                Button("Resume") { resumeSavedGame() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Resume \(difficulty.displayName) game")
                Button("New Game") { viewModel.clearSavedGame() }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Discard saved game and start new")
            }
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(AppTheme.cardCornerRadius)
        .shadow(color: .black.opacity(0.08), radius: AppTheme.cardShadowRadius, x: 0, y: 2)
    }

    private var dailyChallengeCard: some View {
        Button { router.navigate(to: .gamePlay(gameId: "sudoku", context: "daily")) } label: {
            HStack(spacing: 12) {
                Image(systemName: dailyChallenge.isCompletedToday() ? "checkmark.seal.fill" : "calendar")
                    .font(.title2)
                    .foregroundColor(dailyChallenge.isCompletedToday() ? .green : .accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Challenge")
                        .font(.appHeadline)
                        .foregroundColor(.appTextPrimary)
                    Text(dailyChallenge.isCompletedToday()
                         ? "Completed — streak \(dailyChallenge.streak.currentStreak)"
                         : "\(dailyChallenge.todayDifficulty().displayName) · Streak \(dailyChallenge.streak.currentStreak)")
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.appTextSecondary)
            }
            .padding()
            .background(Color.appCard)
            .cornerRadius(AppTheme.cardCornerRadius)
            .shadow(color: .black.opacity(0.08), radius: AppTheme.cardShadowRadius, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open daily challenge")
    }

    private var difficultySheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEW GAME")
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal, AppTheme.standardPadding)
                .padding(.top, AppTheme.standardPadding)
                .padding(.bottom, 8)

            ForEach(SudokuDifficulty.allCases) { difficulty in
                difficultyRow(difficulty)
                if difficulty != SudokuDifficulty.allCases.last {
                    Divider()
                        .padding(.leading, AppTheme.standardPadding + 48)
                }
            }
        }
        .background(Color.appCard)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -4)
    }

    private func difficultyRow(_ difficulty: SudokuDifficulty) -> some View {
        Button {
            startNewGame(difficulty: difficulty)
        } label: {
            HStack(spacing: 16) {
                difficultyIcon(difficulty)
                    .frame(width: 32)
                Text(difficulty.displayName)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }
            .padding(.horizontal, AppTheme.standardPadding)
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start \(difficulty.displayName) game")
    }

    private func difficultyIcon(_ difficulty: SudokuDifficulty) -> some View {
        let bars: Int
        switch difficulty {
        case .easy:   bars = 1
        case .medium: bars = 2
        case .hard:   bars = 3
        case .expert: bars = 4
        }
        return HStack(alignment: .bottom, spacing: 2) {
            ForEach(1...4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= bars ? Color.appTextPrimary : Color.gray.opacity(0.3))
                    .frame(width: 5, height: CGFloat(4 + i * 4))
            }
        }
    }

    private var loadingOverlay: some View {
        Color.black.opacity(0.2)
            .ignoresSafeArea()
            .overlay(
                ProgressView()
                    .scaleEffect(1.5)
            )
    }

    // MARK: - Actions

    private func startNewGame(difficulty: SudokuDifficulty) {
        isLoadingGame = true
        Task {
            let puzzle = await viewModel.getPuzzle(for: difficulty)
            persistence.save(puzzle, key: PersistenceService.Keys.sudokuPendingPuzzle)
            isLoadingGame = false
            router.navigate(to: .gamePlay(gameId: "sudoku", context: difficulty.rawValue))
        }
    }

    private func resumeSavedGame() {
        guard let state = viewModel.loadSavedGame() else { return }
        persistence.save(state.puzzle, key: PersistenceService.Keys.sudokuPendingPuzzle)
        router.navigate(to: .gamePlay(gameId: "sudoku", context: state.puzzle.difficulty.rawValue))
    }
}

// MARK: - Selective corner radius helper

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}
