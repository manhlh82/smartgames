import SwiftUI

/// Stack 2048 lobby — shows best score and a Play button.
struct Stack2048LobbyView: View {
    @StateObject private var bannerCoordinator: BannerAdCoordinator
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var store: StoreService

    private let persistence: PersistenceService
    private let analytics: AnalyticsService

    @State private var progress = Stack2048Progress()

    init(persistence: PersistenceService, ads: AdsService, analytics: AnalyticsService) {
        self.persistence = persistence
        self.analytics = analytics
        _bannerCoordinator = StateObject(wrappedValue: ads.makeBannerCoordinator(gameId: "stack2048", analytics: analytics))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Game logo / icon area
            VStack(spacing: 12) {
                Image(systemName: "square.stack.fill")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.91, green: 0.66, blue: 0.09),
                                     Color(red: 0.96, green: 0.47, blue: 0.23)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Stack 2048")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Drop tiles. Match & merge. How high can you stack?")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Stats
            if progress.gamesPlayed > 0 {
                HStack(spacing: 24) {
                    statBadge(label: "Best Score", value: "\(progress.highScore)")
                    statBadge(label: "Best Tile", value: "\(progress.bestTile)")
                    statBadge(label: "Played", value: "\(progress.gamesPlayed)")
                }
                .padding(.bottom, 24)
            }

            // Play button
            Button {
                router.navigate(to: .gamePlay(gameId: "stack2048", context: "play"))
            } label: {
                Text("Play")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.91, green: 0.66, blue: 0.09),
                                     Color(red: 0.96, green: 0.47, blue: 0.23)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Banner ad
            if !store.hasRemovedAds && bannerCoordinator.isBannerLoaded {
                BannerAdView(coordinator: bannerCoordinator)
                    .frame(height: bannerCoordinator.bannerHeight)
            }
        }
        .navigationTitle("Stack 2048")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                GoldBalanceView()
            }
        }
        .onAppear {
            progress = persistence.load(Stack2048Progress.self, key: PersistenceService.Keys.stack2048Progress) ?? Stack2048Progress()
        }
    }

    private func statBadge(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 72)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
