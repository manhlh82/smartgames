import SwiftUI

/// Main Drop Rush gameplay screen.
/// TimelineView drives the 60fps game loop via viewModel.tick(date:).
struct DropRushGameView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel: DropRushGameViewModel
    @State private var wrongFlashSymbol: String?
    @State private var wrongFlashTask: Task<Void, Never>?

    init(
        levelNumber: Int,
        persistence: PersistenceService,
        sound: SoundService,
        haptics: HapticsService,
        ads: AdsService,
        analytics: AnalyticsService,
        gameCenter: GameCenterService,
        goldService: GoldService,
        diamondService: DiamondService,
        piggyBank: PiggyBankService
    ) {
        _viewModel = StateObject(wrappedValue: DropRushGameViewModel(
            levelNumber: levelNumber,
            persistence: persistence,
            sound: sound,
            haptics: haptics,
            ads: ads,
            analytics: analytics,
            gameCenter: gameCenter,
            goldService: goldService,
            diamondService: diamondService,
            piggyBank: piggyBank
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                DropRushHUDView(
                    state: viewModel.engineState,
                    phase: viewModel.phase,
                    onPause: viewModel.pause,
                    onResume: viewModel.resume
                )

                gameArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                DropRushInputBarView(
                    symbols: viewModel.symbols,
                    wrongFlashSymbol: wrongFlashSymbol,
                    onTap: { symbol in
                        guard viewModel.phase == .playing else { return }
                        let before = viewModel.engineState.wrongTaps
                        viewModel.handleTap(symbol: symbol)
                        if viewModel.engineState.wrongTaps > before {
                            wrongFlashTask?.cancel()
                            wrongFlashSymbol = symbol
                            wrongFlashTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 200_000_000)
                                guard !Task.isCancelled else { return }
                                wrongFlashSymbol = nil
                            }
                        }
                    }
                )
                .padding(.bottom, 4)
                .opacity(viewModel.phase == .playing ? 1.0 : 0.4)
                .allowsHitTesting(viewModel.phase == .playing)
            }

            phaseOverlays
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Level \(viewModel.levelNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.quit()
                    router.pop()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                viewModel.pause()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
    }

    // MARK: - Game Area

    private var gameArea: some View {
        GeometryReader { geo in
            ZStack {
                // Ground indicator
                Rectangle()
                    .fill(Color.red.opacity(0.15))
                    .frame(height: 3)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                // Falling objects + hit effects driven by TimelineView
                TimelineView(.animation) { timeline in
                    ZStack {
                        Color.clear
                            .onChange(of: timeline.date) { date in
                                viewModel.tick(date: date)
                            }

                        let laneWidth = geo.size.width / CGFloat(max(viewModel.symbols.count, 1))
                        ForEach(viewModel.engineState.fallingObjects) { object in
                            FallingItemView(
                                object: object,
                                areaHeight: geo.size.height,
                                laneWidth: laneWidth
                            )
                        }

                        // Burst explosion animations on successful taps
                        ForEach(viewModel.hitEffects) { effect in
                            HitEffectView(effect: effect, areaSize: geo.size)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var phaseOverlays: some View {
        if viewModel.phase == .countdown {
            countdownOverlay
                .transition(.opacity)
        }

        if viewModel.phase == .paused {
            DropRushPauseOverlay(
                onResume: viewModel.resume,
                onQuit: {
                    viewModel.quit()
                    router.pop()
                }
            )
            .transition(.opacity)
        }

        if viewModel.phase == .watchingAd {
            watchingAdOverlay
                .transition(.opacity)
        }

        // Speed-up banner — non-interactive, fades in/out automatically
        if viewModel.showSpeedUpFlash && viewModel.phase == .playing {
            speedUpOverlay
                .transition(.opacity)
                .allowsHitTesting(false)
        }

        if viewModel.phase == .levelComplete {
            DropRushResultOverlay(
                state: viewModel.engineState,
                stars: viewModel.stars,
                isGameOver: false,
                isNewHighScore: viewModel.isNewHighScore,
                continueAvailable: false,
                showPerfectAccuracy: viewModel.showPerfectAccuracy,
                levelNumber: viewModel.levelNumber,
                goldEarned: viewModel.goldEarnedOnWin,
                goldBalance: viewModel.goldService.balance,
                onNextLevel: { router.pop() },
                onRetry: viewModel.retry,
                onLobby: { router.pop() },
                onContinue: {}
            )
            .transition(.scale.combined(with: .opacity))
        }

        if viewModel.phase == .gameOver {
            DropRushResultOverlay(
                state: viewModel.engineState,
                stars: 0,
                isGameOver: true,
                isNewHighScore: false,
                continueAvailable: viewModel.continueAvailable,
                showPerfectAccuracy: false,
                levelNumber: viewModel.levelNumber,
                goldEarned: 0,
                goldBalance: viewModel.goldService.balance,
                onNextLevel: { router.pop() },
                onRetry: viewModel.retry,
                onLobby: { router.pop() },
                onContinue: viewModel.requestContinue
            )
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 8) {
                Text(viewModel.countdownValue > 0 ? "\(viewModel.countdownValue)" : "GO!")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: viewModel.countdownValue)
                Text("Level \(viewModel.levelNumber)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var watchingAdOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("Loading Ad…")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var speedUpOverlay: some View {
        VStack {
            Text("SPEED UP!")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.orange)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.top, 80)
        .frame(maxWidth: .infinity)
    }
}
