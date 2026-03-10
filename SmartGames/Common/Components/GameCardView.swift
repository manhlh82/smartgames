import SwiftUI

/// Reusable game card for the hub screen.
struct GameCardView: View {
    let game: GameEntry

    var body: some View {
        HStack(spacing: 16) {
            // Game icon
            Image(game.iconAsset)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))

            Text(game.displayName)
                .font(.appHeadline)
                .foregroundColor(game.isAvailable ? .appTextPrimary : .appTextSecondary)

            Spacer()

            // Play button
            Button(action: {}) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 52, height: 44)
                    .background(game.isAvailable ? Color.appAccent : Color.gray)
                    .cornerRadius(AppTheme.buttonCornerRadius)
            }
            .disabled(!game.isAvailable)
        }
        .padding(AppTheme.standardPadding)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cardCornerRadius)
        .shadow(color: .black.opacity(AppTheme.cardShadowOpacity), radius: AppTheme.cardShadowRadius, x: 0, y: 2)
    }
}

private extension AppTheme {
    static let cardBackground = Color.white
}
