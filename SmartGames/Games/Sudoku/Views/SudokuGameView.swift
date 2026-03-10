import SwiftUI

/// Main Sudoku gameplay screen.
struct SudokuGameView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    let difficulty: SudokuDifficulty
    @StateObject private var viewModel: SudokuGameViewModel

    init(difficulty: SudokuDifficulty, puzzle: SudokuPuzzle,
         persistence: PersistenceService, analytics: AnalyticsService,
         sound: SoundService, haptics: HapticsService, ads: AdsService) {
        self.difficulty = difficulty
        _viewModel = StateObject(wrappedValue: SudokuGameViewModel(
            puzzle: puzzle,
            persistence: persistence,
            analytics: analytics,
            sound: sound,
            haptics: haptics,
            ads: ads
        ))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                statsBar
                SudokuBoardView(viewModel: viewModel)
                    .padding(.horizontal, 4)
                SudokuToolbarView(viewModel: viewModel)
                    .padding(.horizontal, AppTheme.standardPadding)
                SudokuNumberPadView(
                    onNumberTap: { viewModel.placeNumber($0) },
                    completedNumbers: viewModel.completedNumbers
                )
                .padding(.horizontal, AppTheme.standardPadding)
                Spacer(minLength: 8)
            }
            .padding(.top, 8)

            phaseOverlays
        }
        .navigationBarBackButtonHidden(true)
        .toolbar { gameToolbar }
        .onChange(of: scenePhase) { phase in
            if phase == .background || phase == .inactive {
                viewModel.pause()
            }
        }
        .alert("Watch an ad for 3 more hints?", isPresented: hintAdBinding) {
            Button("Watch Ad") {
                viewModel.ads.showRewardedAd { granted in
                    if granted { viewModel.grantHintsAfterAd() }
                    else { viewModel.cancelHintAd() }
                }
            }
            Button("Cancel", role: .cancel) { viewModel.cancelHintAd() }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.gamePhase)
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack {
            Text("Mistakes: \(viewModel.mistakeCount)/\(viewModel.mistakeLimit)")
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
                .accessibilityLabel("Mistakes: \(viewModel.mistakeCount) of \(viewModel.mistakeLimit)")

            Spacer()

            Text(difficulty.displayName)
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)

            Spacer()

            if viewModel.gamePhase != .paused {
                Text(formatTime(viewModel.elapsedSeconds))
                    .font(.appMono)
                    .foregroundColor(.appTextSecondary)
                    .accessibilityLabel("Elapsed time \(formatTime(viewModel.elapsedSeconds))")
            }
        }
        .padding(.horizontal, AppTheme.standardPadding)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var gameToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { router.pop() } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.appTextPrimary)
            }
            .accessibilityLabel("Back")
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                if viewModel.gamePhase == .playing { viewModel.pause() }
                else if viewModel.gamePhase == .paused { viewModel.resume() }
            } label: {
                Image(systemName: viewModel.gamePhase == .paused ? "play" : "pause")
                    .foregroundColor(.appTextPrimary)
            }
            .accessibilityLabel(viewModel.gamePhase == .paused ? "Resume" : "Pause")
        }
    }

    // MARK: - Phase Overlays

    @ViewBuilder
    private var phaseOverlays: some View {
        if viewModel.gamePhase == .paused {
            SudokuPauseOverlayView(
                onResume: { viewModel.resume() },
                onRestart: { viewModel.restart() },
                onQuit: { router.popToRoot() }
            )
            .transition(.opacity)
        }

        if viewModel.gamePhase == .won {
            Color.black.opacity(0.5).ignoresSafeArea()
            SudokuWinView(
                elapsedSeconds: viewModel.elapsedSeconds,
                mistakes: viewModel.mistakeCount,
                stars: viewModel.starRating,
                difficulty: difficulty,
                onNextPuzzle: { router.pop() },
                onBackToMenu: { router.popToRoot() }
            )
            .transition(.scale.combined(with: .opacity))
        }

        if viewModel.gamePhase == .lost {
            Color.black.opacity(0.5).ignoresSafeArea()
            lostOverlay
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Lost Overlay

    private var lostOverlay: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.appTitle)
                .foregroundColor(.appTextPrimary)
            Text("\(viewModel.mistakeLimit) mistakes reached")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)

            VStack(spacing: 12) {
                PrimaryButton(title: "Try Again") { viewModel.restart() }

                Button("New Game") { router.pop() }
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .accessibilityLabel("Back to lobby for new game")

                Button("Watch Ad to Continue") {
                    viewModel.ads.showRewardedAd { granted in
                        if granted {
                            viewModel.mistakeCount = viewModel.mistakeLimit - 1
                            viewModel.gamePhase = .playing
                            viewModel.resume()
                        }
                    }
                }
                .font(.appBody)
                .foregroundColor(.appAccent)
                .accessibilityLabel("Watch ad to continue with one mistake forgiven")
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 20)
        .padding(AppTheme.standardPadding)
    }

    // MARK: - Helpers

    private var hintAdBinding: Binding<Bool> {
        Binding(
            get: { viewModel.gamePhase == .needsHintAd },
            set: { if !$0 { viewModel.cancelHintAd() } }
        )
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
