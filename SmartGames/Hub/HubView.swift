import SwiftUI

/// Main game hub — shows list of available games.
struct HubView: View {
    @StateObject private var viewModel = HubViewModel()
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.games) { game in
                    GameCardView(game: game)
                        .padding(.horizontal, AppTheme.standardPadding)
                }
            }
            .padding(.vertical, AppTheme.standardPadding)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("SmartGames")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.appTextPrimary)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .safeAreaInset(edge: .bottom) {
            // Footer links
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
