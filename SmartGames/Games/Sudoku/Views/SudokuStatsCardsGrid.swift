import SwiftUI

/// Grid of stat cards displayed in SudokuStatisticsView.
struct StatsCardsGrid: View {
    let stats: SudokuStats

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatCard(title: "Games Played",
                     value: "\(stats.gamesPlayed)",
                     icon: "gamecontroller")
            StatCard(title: "Win Rate",
                     value: winRateText,
                     icon: "percent")
            StatCard(title: "Best Time",
                     value: formatTime(stats.bestTimeSeconds),
                     icon: "stopwatch")
            StatCard(title: "Avg Time",
                     value: formatAvgTime(stats),
                     icon: "clock")
            StatCard(title: "Current Streak",
                     value: "\(stats.currentStreak)",
                     icon: "flame")
            StatCard(title: "Best Streak",
                     value: "\(stats.bestStreak)",
                     icon: "trophy")
        }
    }

    // MARK: - Helpers

    private var winRateText: String {
        guard stats.gamesPlayed > 0 else { return "0%" }
        let rate = Double(stats.gamesWon) / Double(stats.gamesPlayed) * 100
        return String(format: "%.0f%%", rate)
    }

    private func formatTime(_ seconds: Int) -> String {
        guard seconds < Int.max else { return "--:--" }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func formatAvgTime(_ stats: SudokuStats) -> String {
        guard stats.gamesWon > 0 else { return "--:--" }
        let avg = stats.totalTimeSeconds / stats.gamesWon
        return String(format: "%02d:%02d", avg / 60, avg % 60)
    }
}

// MARK: - Single Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appAccent)
                Text(title)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.appTextPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.standardPadding)
        .background(Color.appCard)
        .cornerRadius(AppTheme.cardCornerRadius)
        .shadow(color: .black.opacity(AppTheme.cardShadowOpacity),
                radius: AppTheme.cardShadowRadius, x: 0, y: 2)
    }
}
