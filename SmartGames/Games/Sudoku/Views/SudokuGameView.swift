import SwiftUI

/// Main Sudoku gameplay screen.
struct SudokuGameView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    let difficulty: SudokuDifficulty
    @StateObject private var viewModel: SudokuGameViewModel
    @StateObject private var bannerCoordinator: BannerAdCoordinator
    @State private var showRestartConfirm = false

    private let monetizationConfig: MonetizationConfig
    private let storeService: StoreService?

    init(difficulty: SudokuDifficulty, puzzle: SudokuPuzzle,
         persistence: PersistenceService, analytics: AnalyticsService,
         sound: SoundService, haptics: HapticsService, ads: AdsService,
         statisticsService: StatisticsService, gameCenterService: GameCenterService,
         dailyChallengeService: DailyChallengeService? = nil,
         storeService: StoreService? = nil,
         monetizationConfig: MonetizationConfig = MonetizationConfig()) {
        self.difficulty = difficulty
        self.storeService = storeService
        self.monetizationConfig = monetizationConfig
        let vm = SudokuGameViewModel(
            puzzle: puzzle,
            persistence: persistence,
            analytics: analytics,
            sound: sound,
            haptics: haptics,
            ads: ads,
            statisticsService: statisticsService,
            gameCenterService: gameCenterService,
            dailyChallengeService: dailyChallengeService,
            monetizationConfig: monetizationConfig
        )
        vm.storeService = storeService
        _viewModel = StateObject(wrappedValue: vm)
        _bannerCoordinator = StateObject(wrappedValue: ads.makeBannerCoordinator())
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
                    completedNumbers: viewModel.completedNumbers,
                    selectedNumber: viewModel.selectedCell.flatMap {
                        viewModel.puzzle.board[$0.row][$0.col].value
                    },
                    remainingCounts: viewModel.remainingCounts
                )
                .padding(.horizontal, AppTheme.standardPadding)
                Spacer(minLength: 8)

                // Banner ad — visible during active gameplay only, hidden when ads removed
                if monetizationConfig.bannerEnabled
                    && storeService?.hasRemovedAds != true
                    && (viewModel.gamePhase == .playing || viewModel.gamePhase == .paused) {
                    BannerAdView(coordinator: bannerCoordinator)
                        .frame(height: bannerCoordinator.isBannerLoaded ? bannerCoordinator.bannerHeight : 50)
                        .animation(.easeInOut(duration: 0.3), value: bannerCoordinator.isBannerLoaded)
                }
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
        .alert("Reset Mistakes?", isPresented: mistakeResetAdBinding) {
            Button("Watch Ad") {
                viewModel.ads.showRewardedAd { granted in
                    if granted { viewModel.grantMistakeResetAfterAd() }
                    else { viewModel.cancelMistakeResetAd() }
                }
            }
            Button("Cancel", role: .cancel) { viewModel.cancelMistakeResetAd() }
        } message: {
            Text("Watch a short video to reset your mistakes to zero.")
        }
        .confirmationDialog("Restart this puzzle?", isPresented: $showRestartConfirm) {
            Button("Restart", role: .destructive) { viewModel.restart() }
            Button("Cancel", role: .cancel) {}
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.gamePhase)
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack {
            // Mistakes counter + optional reset button
            HStack(spacing: 6) {
                Text("Mistakes: \(viewModel.mistakeCount)/\(viewModel.mistakeLimit)")
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
                    .accessibilityLabel("Mistakes: \(viewModel.mistakeCount) of \(viewModel.mistakeLimit)")

                if viewModel.canResetMistakes {
                    Button(action: { viewModel.requestMistakeReset() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .medium))
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .controlSize(.mini)
                    .accessibilityLabel("Watch ad to reset mistakes")
                }
            }

            Spacer()

            Text(difficulty.displayName)
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)

            Spacer()

            Text(formatTime(viewModel.elapsedSeconds))
                .font(.appMono)
                .foregroundColor(.appTextSecondary)
                .opacity(viewModel.gamePhase == .paused ? 0.4 : 1.0)
                .accessibilityLabel("Elapsed time \(formatTime(viewModel.elapsedSeconds))")
        }
        .padding(.horizontal, AppTheme.standardPadding)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var gameToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                // Save state before navigating away — debounced auto-save may not have fired yet
                viewModel.autoSave()
                router.pop()
            } label: {
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
                onRestart: { showRestartConfirm = true },
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
                        if granted { viewModel.continueAfterAd() }
                    }
                }
                .font(.appBody)
                .foregroundColor(.appAccent)
                .accessibilityLabel("Watch ad to continue with one mistake forgiven")
            }
        }
        .padding(24)
        .background(Color.appCard)
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

    private var mistakeResetAdBinding: Binding<Bool> {
        Binding(
            get: { viewModel.gamePhase == .needsMistakeResetAd },
            set: { if !$0 { viewModel.cancelMistakeResetAd() } }
        )
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
