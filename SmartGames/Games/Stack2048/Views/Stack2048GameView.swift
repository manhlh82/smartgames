import SwiftUI

/// Main Stack 2048 gameplay screen.
struct Stack2048GameView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel: Stack2048GameViewModel
    @State private var boardFrame: CGRect = .zero

    init(
        persistence: PersistenceService,
        sound: SoundService,
        haptics: HapticsService,
        ads: AdsService,
        analytics: AnalyticsService,
        goldService: GoldService,
        diamondService: DiamondService,
        piggyBank: PiggyBankService,
        challengeLevel: Stack2048ChallengeLevel? = nil,
        dailyInitialTiles: [(col: Int, value: Int)]? = nil,
        onDailyComplete: ((Int) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: Stack2048GameViewModel(
            persistence: persistence,
            sound: sound,
            haptics: haptics,
            ads: ads,
            analytics: analytics,
            goldService: goldService,
            diamondService: diamondService,
            piggyBank: piggyBank,
            challengeLevel: challengeLevel,
            dailyInitialTiles: dailyInitialTiles,
            onDailyComplete: onDailyComplete
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
                    onResume: viewModel.resume,
                    challengeInfo: viewModel.challengeLevel.map { level in
                        (targetTile: level.targetTile, movesUsed: viewModel.challengeMoveCount)
                    }
                )

                Stack2048BoardView(
                    gameState: viewModel.gameState,
                    phase: viewModel.phase,
                    dragTargetColumn: viewModel.dragTargetColumn,
                    ghostTile: viewModel.gameState.nextTile,
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
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { boardFrame = geo.frame(in: .global) }
                            .onChange(of: geo.frame(in: .global)) { frame in
                                boardFrame = frame
                            }
                    }
                )

                Stack2048ControlBarView(
                    nextTile: viewModel.gameState.nextTile,
                    goldBalance: viewModel.goldService.balance,
                    phase: viewModel.phase,
                    isAdReady: viewModel.ads.isRewardedAdReady,
                    boardFrame: boardFrame,
                    onHammer: viewModel.useHammer,
                    onShuffle: viewModel.useShuffle,
                    onCancelHammer: viewModel.cancelHammer,
                    onRequestAd: viewModel.requestAdGold,
                    onDragChanged: { col in
                        viewModel.setDragTarget(col)
                    },
                    onDragEnded: { col in
                        if let col {
                            viewModel.confirmDrop(into: col)
                        } else {
                            viewModel.setDragTarget(nil)
                        }
                    }
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
                diamondBalance: viewModel.diamondService.balance,
                isAdReady: viewModel.ads.isRewardedAdReady,
                onRetry: viewModel.retry,
                onQuit: {
                    viewModel.quit()
                    router.pop()
                },
                onWatchAdContinue: viewModel.requestAdContinue,
                onDiamondContinue: viewModel.requestDiamondContinue
            )
            .transition(.scale.combined(with: .opacity))
        }

        if viewModel.phase == .won {
            Stack2048WinOverlay(
                score: viewModel.gameState.score,
                goldEarned: GoldReward.stack2048Win,
                goldBalance: viewModel.goldService.balance,
                onKeepPlaying: viewModel.keepPlaying,
                onNewGame: viewModel.retry
            )
            .transition(.scale.combined(with: .opacity))
        }

        if case .challengeComplete(let stars) = viewModel.phase {
            Stack2048ChallengeCompleteOverlay(
                stars: stars,
                goldEarned: viewModel.goldEarnedOnEnd,
                goldBalance: viewModel.goldService.balance,
                levelNumber: viewModel.challengeLevel?.level ?? 0,
                onNextLevel: {
                    if let nextLevel = viewModel.nextChallengeLevel() {
                        router.navigate(to: .gamePlay(gameId: "stack2048", context: "challenge-\(nextLevel.level)"))
                    } else {
                        router.pop()
                    }
                },
                onRetry: viewModel.retryChallenge,
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
