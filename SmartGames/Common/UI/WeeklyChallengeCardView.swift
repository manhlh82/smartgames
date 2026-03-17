import SwiftUI

/// Compact card showing the current week's best score for a game + leaderboard button.
struct WeeklyChallengeCardView: View {
    let game: String
    let bestScore: Int
    let onViewLeaderboard: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Challenge")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(gameDisplayName)
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(bestScore > 0 ? "Best: \(bestScore)" : "No score yet")
                        .font(.subheadline)
                        .foregroundColor(bestScore > 0 ? .primary : .secondary)
                }
            }
            Spacer()
            Button(action: onViewLeaderboard) {
                Label("Leaderboard", systemImage: "list.number")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var gameDisplayName: String {
        switch game {
        case "sudoku":   return "Sudoku"
        case "dropRush": return "Drop Rush"
        case "stack2048": return "Stack 2048"
        default:         return game.capitalized
        }
    }
}
