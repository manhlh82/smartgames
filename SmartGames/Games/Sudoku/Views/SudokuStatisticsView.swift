import SwiftUI

/// Statistics screen showing per-difficulty Sudoku performance metrics.
struct SudokuStatisticsView: View {
    @EnvironmentObject private var statisticsService: StatisticsService
    @EnvironmentObject private var router: AppRouter

    @State private var selectedTab: StatsTab = .all
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                tabPicker
                    .padding(.horizontal, AppTheme.standardPadding)
                    .padding(.top, AppTheme.standardPadding)
                    .padding(.bottom, 12)

                ScrollView {
                    let stats = currentStats
                    if stats.gamesPlayed == 0 {
                        emptyState
                            .padding(.top, 60)
                    } else {
                        StatsCardsGrid(stats: stats)
                            .padding(.horizontal, AppTheme.standardPadding)
                            .padding(.top, 8)
                    }

                    resetButton
                        .padding(.horizontal, AppTheme.standardPadding)
                        .padding(.top, 24)
                        .padding(.bottom, AppTheme.standardPadding)
                }
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .alert("Reset Statistics", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                statisticsService.resetStats(for: selectedTab.difficulty)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(resetAlertMessage)
        }
    }

    // MARK: - Subviews

    private var tabPicker: some View {
        Picker("Difficulty", selection: $selectedTab) {
            ForEach(StatsTab.allCases, id: \.self) { tab in
                Text(tab.label).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundColor(.appTextSecondary)
            Text("No games played yet")
                .font(.appHeadline)
                .foregroundColor(.appTextSecondary)
            Text("Complete a game to see your stats here.")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppTheme.standardPadding)
    }

    private var resetButton: some View {
        Button {
            showResetConfirm = true
        } label: {
            Text("Reset Statistics")
                .font(.appBody)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(AppTheme.cardCornerRadius)
                .shadow(color: .black.opacity(AppTheme.cardShadowOpacity),
                        radius: AppTheme.cardShadowRadius, x: 0, y: 2)
        }
        .accessibilityLabel("Reset statistics for \(selectedTab.label)")
    }

    // MARK: - Helpers

    private var currentStats: SudokuStats {
        if let difficulty = selectedTab.difficulty {
            return statisticsService.stats(for: difficulty)
        }
        return statisticsService.aggregateStats()
    }

    private var resetAlertMessage: String {
        if let difficulty = selectedTab.difficulty {
            return "This will permanently clear all \(difficulty.displayName) statistics."
        }
        return "This will permanently clear statistics for all difficulties."
    }
}

// MARK: - Tab Model

enum StatsTab: CaseIterable {
    case all, easy, medium, hard, expert

    var label: String {
        switch self {
        case .all:    return "All"
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        case .expert: return "Expert"
        }
    }

    var difficulty: SudokuDifficulty? {
        switch self {
        case .all:    return nil
        case .easy:   return .easy
        case .medium: return .medium
        case .hard:   return .hard
        case .expert: return .expert
        }
    }
}
