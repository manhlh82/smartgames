import SwiftUI

/// Popup shown once per week displaying tier achieved + rewards earned per game.
struct WeeklyChallengeResultView: View {
    let result: WeeklyRewardResult
    let onClaim: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                VStack(spacing: 6) {
                    Text("Weekly Results")
                        .font(.title2.bold())
                    Text("Here's how you placed this week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Per-game reward rows
                VStack(spacing: 12) {
                    ForEach(result.gameRewards, id: \.game) { reward in
                        RewardRowView(reward: reward)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)

                // Claim button
                Button(action: onClaim) {
                    Text("Claim Rewards")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Reward Row

private struct RewardRowView: View {
    let reward: WeeklyGameReward

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(gameDisplayName)
                    .font(.subheadline.bold())
                Text(tierLabel)
                    .font(.caption)
                    .foregroundColor(tierColor)
            }
            Spacer()
            HStack(spacing: 8) {
                Label("\(reward.gold)", systemImage: "circle.fill")
                    .foregroundColor(.yellow)
                    .font(.subheadline)
                if reward.diamonds > 0 {
                    Label("\(reward.diamonds)", systemImage: "diamond.fill")
                        .foregroundColor(.cyan)
                        .font(.subheadline)
                }
            }
        }
    }

    private var gameDisplayName: String {
        switch reward.game {
        case "sudoku":    return "Sudoku"
        case "dropRush":  return "Drop Rush"
        case "stack2048": return "Stack 2048"
        default:          return reward.game.capitalized
        }
    }

    private var tierLabel: String {
        switch reward.tier {
        case .top1:          return "Top 1%"
        case .top5:          return "Top 5%"
        case .top25:         return "Top 25%"
        case .top50:         return "Top 50%"
        case .participation: return "Participation"
        }
    }

    private var tierColor: Color {
        switch reward.tier {
        case .top1:          return .yellow
        case .top5:          return .orange
        case .top25:         return .blue
        case .top50:         return .green
        case .participation: return .secondary
        }
    }
}
