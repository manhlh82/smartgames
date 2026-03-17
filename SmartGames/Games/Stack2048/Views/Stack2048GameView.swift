import SwiftUI

/// Main Stack 2048 gameplay screen.
struct Stack2048GameView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel: Stack2048GameViewModel

    init(
        persistence: PersistenceService,
        sound: SoundService,
        haptics: HapticsService,
        ads: AdsService,
        analytics: AnalyticsService,
        goldService: GoldService
    ) {
        _viewModel = StateObject(wrappedValue: Stack2048GameViewModel(
            persistence: persistence,
            sound: sound,
            haptics: haptics,
            ads: ads,
            analytics: analytics,
            goldService: goldService
        ))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Stack2048HUDView(
                    score: viewModel.gameState.score,
                    highScore: viewModel.highScore,
                    phase: viewModel.phase,
                    onPause: viewModel.pause,
                    onResume: viewModel.resume
                )

                Stack2048BoardView(
                    gameState: viewModel.gameState,
                    phase: viewModel.phase,
                    onColumnTap: { col in
                        viewModel.dropTile(into: col)
                    },
                    onTileTap: { col, row in
                        viewModel.tapTileForHammer(column: col, row: row)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

                Stack2048ControlBarView(
                    nextTile: viewModel.gameState.nextTile,
                    goldBalance: viewModel.goldService.balance,
                    phase: viewModel.phase,
                    isAdReady: viewModel.ads.isRewardedAdReady,
                    onHammer: viewModel.useHammer,
                    onShuffle: viewModel.useShuffle,
                    onCancelHammer: viewModel.cancelHammer,
                    onRequestAd: viewModel.requestAdGold
                )
                .padding(.bottom, 8)
            }

            phaseOverlays
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.quit()
                    router.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
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

    // MARK: - Phase Overlays

    @ViewBuilder
    private var phaseOverlays: some View {
        if viewModel.phase == .paused {
            Stack2048PauseOverlay(
                score: viewModel.gameState.score,
                onResume: viewModel.resume,
                onQuit: {
                    viewModel.quit()
                    router.pop()
                }
            )
            .transition(.opacity)
        }

        if viewModel.phase == .hammerMode {
            hammerModeHint
                .transition(.opacity)
                .allowsHitTesting(false)
        }

        if viewModel.phase == .watchingAd {
            watchingAdOverlay
                .transition(.opacity)
        }

        if viewModel.phase == .gameOver {
            Stack2048GameOverOverlay(
                score: viewModel.gameState.score,
                highScore: viewModel.highScore,
                isNewHighScore: viewModel.isNewHighScore,
                goldEarned: viewModel.goldEarnedOnEnd,
                goldBalance: viewModel.goldService.balance,
                onRetry: viewModel.retry,
                onQuit: {
                    viewModel.quit()
                    router.pop()
                }
            )
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var hammerModeHint: some View {
        VStack {
            Text("Tap a tile to destroy it")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.75))
                .clipShape(Capsule())
                .padding(.top, 70)
            Spacer()
        }
        .frame(maxWidth: .infinity)
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
}
