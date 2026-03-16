import SwiftUI

/// Drop Rush lobby — level select grid with progress header and banner ad.
struct DropRushLobbyView: View {
    @StateObject private var viewModel: DropRushLobbyViewModel
    @StateObject private var bannerCoordinator: BannerAdCoordinator
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var store: StoreService
    @EnvironmentObject private var gameCenter: GameCenterService

    init(persistence: PersistenceService, ads: AdsService, analytics: AnalyticsService) {
        _viewModel = StateObject(wrappedValue: DropRushLobbyViewModel(persistence: persistence))
        _bannerCoordinator = StateObject(wrappedValue: ads.makeBannerCoordinator(gameId: "dropRush", analytics: analytics))
    }

    var body: some View {
        VStack(spacing: 0) {
            progressHeader
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)

            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 12) {
                    ForEach(viewModel.levels, id: \.levelNumber) { config in
                        LevelCellView(
                            level: config.levelNumber,
                            stars: viewModel.progress.starsForLevel(config.levelNumber),
                            isUnlocked: viewModel.progress.isUnlocked(config.levelNumber),
                            onTap: {
                                router.navigate(to: .gamePlay(gameId: "dropRush", context: "level-\(config.levelNumber)"))
                            }
                        )
                    }
                }
                .padding(16)
            }

            if !store.hasRemovedAds && bannerCoordinator.isBannerLoaded {
                BannerAdView(coordinator: bannerCoordinator)
                    .frame(height: bannerCoordinator.bannerHeight)
            }
        }
        .navigationTitle("Drop Rush")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                GoldBalanceView()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    gameCenter.showDropRushLeaderboard()
                } label: {
                    Image(systemName: "trophy.fill")
                }
                .disabled(!gameCenter.isAuthenticated)
            }
        }
        .onAppear { viewModel.refreshProgress() }
    }

    private var progressHeader: some View {
        HStack {
            Label("\(viewModel.progress.totalStars) / \(viewModel.levels.count * 3)", systemImage: "star.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.yellow)

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("BEST SCORE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("\(viewModel.progress.cumulativeHighScore)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
        }
    }
}
