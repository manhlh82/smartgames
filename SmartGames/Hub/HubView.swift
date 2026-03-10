import SwiftUI

/// Main game hub — shows list of available games.
struct HubView: View {
    @StateObject private var viewModel = HubViewModel()

    var body: some View {
        List(viewModel.games) { game in
            GameCardView(game: game)
        }
        .navigationTitle("SmartGames")
        .listStyle(.plain)
    }
}
