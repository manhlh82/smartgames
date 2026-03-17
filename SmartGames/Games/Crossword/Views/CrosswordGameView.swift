import SwiftUI

/// Main Crossword gameplay screen.
struct CrosswordGameView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel: CrosswordGameViewModel
    @StateObject private var bannerCoordinator: BannerAdCoordinator
    @State private var showRestartConfirm = false
    @State private var showAdUnavailableAlert = false
    @State private var showClueList = false
    @FocusState private var isKeyboardFocused: Bool
    @State private var keyboardInput: String = ""

    private let monetizationConfig: MonetizationConfig

    init(puzzle: CrosswordPuzzle,
         persistence: PersistenceService,
         analytics: AnalyticsService,
         sound: SoundService,
         haptics: HapticsService,
         ads: AdsService,
         goldService: GoldService,
         diamondService: DiamondService,
         monetizationConfig: MonetizationConfig = MonetizationConfig(),
         dailyChallengeService: CrosswordDailyChallengeService? = nil,
         gameCenterService: GameCenterService) {
        self.monetizationConfig = monetizationConfig
        let vm = CrosswordGameViewModel(
            puzzle: puzzle,
            persistence: persistence,
            analytics: analytics,
            sound: sound,
            haptics: haptics,
            ads: ads,
            goldService: goldService,
            diamondService: diamondService,
            monetizationConfig: monetizationConfig,
            dailyChallengeService: dailyChallengeService,
            gameCenterService: gameCenterService
        )
        _viewModel = StateObject(wrappedValue: vm)
        _bannerCoordinator = StateObject(wrappedValue: ads.makeBannerCoordinator(
            gameId: "crossword", analytics: analytics))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                statsBar
                    .padding(.horizontal, AppTheme.standardPadding)
                    .padding(.vertical, 8)

                CrosswordGridView(viewModel: viewModel)
                    .padding(.horizontal, AppTheme.standardPadding)

                CrosswordClueBarView(viewModel: viewModel)
                    .padding(.top, 8)
                    .onTapGesture { showClueList = true }

                CrosswordToolbarView(viewModel: viewModel)
                    .padding(.vertical, 12)

                Spacer(minLength: 8)

                if monetizationConfig.bannerEnabled && viewModel.gamePhase == .playing {
                    BannerAdView(coordinator: bannerCoordinator)
                        .frame(height: bannerCoordinator.isBannerLoaded
                               ? bannerCoordinator.bannerHeight : 50)
                }
            }

            phaseOverlays

            // Hidden text field to capture hardware/software keyboard input
            TextField("", text: $keyboardInput)
                .focused($isKeyboardFocused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: keyboardInput) { newVal in
                    handleKeyboardInput(newVal)
                }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar { gameToolbar }
        .sheet(isPresented: $showClueList) {
            CrosswordClueListView(viewModel: viewModel)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background || phase == .inactive { viewModel.pause() }
        }
        .onChange(of: viewModel.selectedRow) { _ in isKeyboardFocused = true }
        .alert("Watch an ad for \(monetizationConfig.rewardedHintAmount) more hints?",
               isPresented: hintAdBinding) {
            Button("Watch Ad") {
                guard viewModel.ads.isRewardedAdReady else {
                    viewModel.cancelHintAd()
                    showAdUnavailableAlert = true
                    return
                }
                viewModel.ads.showRewardedAd { granted in
                    if granted { viewModel.grantHintsAfterAd() }
                    else { viewModel.cancelHintAd() }
                }
            }
            Button("Cancel", role: .cancel) { viewModel.cancelHintAd() }
        }
        .alert("Ad Not Available", isPresented: $showAdUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No ad available right now. Please try again later.")
        }
        .confirmationDialog("Restart this puzzle?", isPresented: $showRestartConfirm) {
            Button("Restart", role: .destructive) { viewModel.restart() }
            Button("Cancel", role: .cancel) {}
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.gamePhase)
        .onAppear { isKeyboardFocused = true }
        .onDisappear { viewModel.autoSave() }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack {
            Text("Hints: \(viewModel.hintsRemaining)")
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(viewModel.puzzle.difficulty.displayName)
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(formatTime(viewModel.elapsedSeconds))
                .font(.appMono)
                .foregroundColor(.appTextSecondary)
                .opacity(viewModel.gamePhase == .paused ? 0.4 : 1.0)
        }
    }

    // MARK: - Navigation Toolbar

    @ToolbarContentBuilder
    private var gameToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
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
            .disabled(viewModel.gamePhase != .playing && viewModel.gamePhase != .paused)
        }
    }

    // MARK: - Phase Overlays

    @ViewBuilder
    private var phaseOverlays: some View {
        if viewModel.gamePhase == .paused {
            CrosswordPauseOverlay(
                onResume: { viewModel.resume() },
                onRestart: { showRestartConfirm = true },
                onQuit: { router.popToRoot() }
            )
            .transition(.opacity)
        }
        if viewModel.gamePhase == .won {
            Color.black.opacity(0.5).ignoresSafeArea()
            CrosswordWinView(
                elapsedSeconds: viewModel.elapsedSeconds,
                hintsUsed: viewModel.hintsUsedTotal,
                stars: viewModel.starRating,
                hintsGranted: viewModel.hintsGrantedOnWin,
                goldEarned: viewModel.goldEarnedOnWin,
                onNextPuzzle: { router.pop() },
                onBackToMenu: { router.popToRoot() }
            )
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Keyboard Capture

    private func handleKeyboardInput(_ newVal: String) {
        guard !newVal.isEmpty else { return }
        keyboardInput = ""
        let upper = newVal.uppercased()
        // Backspace / delete
        if upper == "\u{8}" || upper == "\u{7F}" || newVal == "\u{8}" {
            viewModel.deleteLetter()
        } else if let char = upper.first, char.isLetter {
            viewModel.inputLetter(char)
        }
    }

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
