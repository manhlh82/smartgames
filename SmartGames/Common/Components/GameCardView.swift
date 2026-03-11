import SwiftUI

/// Reusable game card for the hub screen.
/// Shows game icon, name, and play button. Disabled state for coming-soon games.
struct GameCardView: View {
    let game: GameEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: { if game.isAvailable { onTap() } }) {
            HStack(spacing: 16) {
                // Game icon — circle with asset or placeholder
                Group {
                    if UIImage(named: game.iconName) != nil {
                        Image(game.iconName)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "gamecontroller.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .foregroundColor(.appAccent)
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.15), lineWidth: 1))
                .background(Circle().fill(Color.appBackground))

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.displayName)
                        .font(.appHeadline)
                        .foregroundColor(game.isAvailable ? .appTextPrimary : .appTextSecondary)
                    if !game.isAvailable {
                        Text("Coming Soon")
                            .font(.appCaption)
                            .foregroundColor(.appTextSecondary)
                    }
                }

                Spacer()

                // Play button
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 52, height: 44)
                    .background(game.isAvailable ? Color.appAccent : Color.gray.opacity(0.4))
                    .cornerRadius(AppTheme.buttonCornerRadius)
            }
            .padding(AppTheme.standardPadding)
            .background(Color.white)
            .cornerRadius(AppTheme.cardCornerRadius)
            .shadow(color: .black.opacity(AppTheme.cardShadowOpacity), radius: AppTheme.cardShadowRadius, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .opacity(game.isAvailable ? 1.0 : 0.6)
        .accessibilityLabel("\(game.displayName)\(game.isAvailable ? "" : ", coming soon")")
        .accessibilityHint(game.isAvailable ? "Double-tap to play" : "Not yet available")
    }
}
