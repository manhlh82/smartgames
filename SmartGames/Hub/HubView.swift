import SwiftUI

/// Main game hub — shows list of available games.
struct HubView: View {
    @StateObject private var viewModel = HubViewModel()
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var analytics: AnalyticsService
    @EnvironmentObject private var gameRegistry: GameRegistry
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.games) { game in
                    GameCardView(game: game) {
                        analytics.log(.gameSelected(gameId: game.id))
                        router.navigate(to: .gameLobby(gameId: game.id))
                    }
                    .padding(.horizontal, AppTheme.standardPadding)
                }
            }
            .padding(.vertical, AppTheme.standardPadding)
        }
        .onAppear {
            viewModel.loadGames(from: gameRegistry)
            analytics.log(.hubViewed)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("SmartGames")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                GoldBalanceView()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    analytics.log(.settingsOpened)
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.appTextPrimary)
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Link("Privacy Policy", destination: URL(string: "https://smartgames.app/privacy")!)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
                Spacer()
                Link("Terms of Service", destination: URL(string: "https://smartgames.app/terms")!)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, AppTheme.standardPadding)
            .padding(.vertical, 8)
            .background(Color.appBackground)
        }
    }
}
