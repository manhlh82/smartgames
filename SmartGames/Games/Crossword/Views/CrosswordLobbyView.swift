import SwiftUI

/// Crossword game entry point — theme/pack selection when packs available, difficulty picker fallback.
struct CrosswordLobbyView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var analytics: AnalyticsService
    @EnvironmentObject private var gameCenterService: GameCenterService
    @EnvironmentObject private var crosswordDailyChallenge: CrosswordDailyChallengeService

    private let puzzleBank: CrosswordPuzzleBank
    private let persistence: PersistenceService

    @State private var hasSavedGame = false
    @State private var savedDifficulty: CrosswordDifficulty? = nil
    @State private var selectedTheme: String? = nil

    init(puzzleBank: CrosswordPuzzleBank, persistence: PersistenceService) {
        self.puzzleBank = puzzleBank
        self.persistence = persistence
    }

    private let themeInfo: [String: (emoji: String, name: String)] = [
        "animals": ("🐾", "Animals"), "food": ("🍕", "Food"),
        "ocean": ("🌊", "Ocean"), "space": ("🚀", "Space"),
        "nature": ("🌿", "Nature"), "sports": ("⚽", "Sports"),
        "music": ("🎵", "Music"), "travel": ("✈️", "Travel"),
        "city": ("🏙️", "City"), "school": ("📚", "School"),
        "weather": ("⛅", "Weather"), "fruits": ("🍎", "Fruits"),
        "mixed": ("🎯", "Mixed"),
    ]

    private var allPacks: [CrosswordPackMeta] { puzzleBank.allPackMeta() }
    private var hasPackContent: Bool { !allPacks.isEmpty }

    /// Unique themes from loaded packs, preserving first-seen order.
    private var availableThemes: [String] {
        var seen = Set<String>()
        return allPacks.compactMap { meta -> String? in
            guard seen.insert(meta.theme).inserted else { return nil }
            return meta.theme
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                titleSection.padding(.bottom, 20)

                dailyChallengeCard
                    .padding(.horizontal, AppTheme.standardPadding)
                    .padding(.bottom, 12)

                if hasSavedGame, let diff = savedDifficulty {
                    resumeCard(difficulty: diff)
                        .padding(.horizontal, AppTheme.standardPadding)
                        .padding(.bottom, 12)
                }

                if hasPackContent {
                    packContentSheet
                } else {
                    difficultySheet
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { GoldBalanceView() }
            ToolbarItem(placement: .navigationBarTrailing) {
                if gameCenterService.isAuthenticated {
                    Button {
                        gameCenterService.showLeaderboard()
                    } label: {
                        Image(systemName: "trophy").foregroundColor(.appTextPrimary)
                    }
                    .accessibilityLabel("View leaderboards")
                }
            }
        }
        .onAppear { checkSavedGame() }
    }

    // MARK: - Subviews

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text("Crossword")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.appTextPrimary)
            Text("Fill in the grid.")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
        }
    }

    private var dailyChallengeCard: some View {
        Button { startDailyChallenge() } label: {
            HStack(spacing: 12) {
                Image(systemName: crosswordDailyChallenge.isCompletedToday()
                      ? "checkmark.seal.fill" : "calendar")
                    .font(.title2)
                    .foregroundColor(crosswordDailyChallenge.isCompletedToday() ? .green : .accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Challenge")
                        .font(.appHeadline)
                        .foregroundColor(.appTextPrimary)
                    Text(crosswordDailyChallenge.isCompletedToday()
                         ? "Completed · Streak \(crosswordDailyChallenge.streak.currentStreak)"
                         : "\(crosswordDailyChallenge.todayDifficultyLabel()) · Streak \(crosswordDailyChallenge.streak.currentStreak)")
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.appTextSecondary)
            }
            .padding()
            .background(Color.appCard)
            .cornerRadius(AppTheme.cardCornerRadius)
            .shadow(color: .black.opacity(0.08), radius: AppTheme.cardShadowRadius, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open daily crossword challenge")
    }

    private func resumeCard(difficulty: CrosswordDifficulty) -> some View {
        VStack(spacing: 8) {
            Text("Resume \(difficulty.displayName)")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
            HStack(spacing: 12) {
                Button("Resume") { resumeSavedGame(difficulty: difficulty) }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Resume \(difficulty.displayName) game")
                Button("New Game") { clearSavedGame() }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Discard saved game and start new")
            }
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(AppTheme.cardCornerRadius)
        .shadow(color: .black.opacity(0.08), radius: AppTheme.cardShadowRadius, x: 0, y: 2)
    }

    // MARK: - Pack content sheet (theme grid + pack list)

    private var packContentSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let theme = selectedTheme {
                packListSection(for: theme)
            } else {
                themeGridSection
            }
        }
        .background(Color.appCard)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -4)
    }

    private var themeGridSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CHOOSE THEME")
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal, AppTheme.standardPadding)
                .padding(.top, AppTheme.standardPadding)
                .padding(.bottom, 12)

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(availableThemes, id: \.self) { theme in
                        themeCell(theme: theme)
                    }
                }
                .padding(.horizontal, AppTheme.standardPadding)
                .padding(.bottom, AppTheme.standardPadding)
            }
            .frame(maxHeight: 280)
        }
    }

    private func themeCell(theme: String) -> some View {
        let info = themeInfo[theme] ?? ("🎯", theme.capitalized)
        return Button { selectedTheme = theme } label: {
            VStack(spacing: 6) {
                Text(info.emoji)
                    .font(.system(size: 32))
                Text(info.name)
                    .font(.appCaption)
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(info.name) theme")
    }

    private func packListSection(for theme: String) -> some View {
        let themePacks = allPacks.filter { $0.theme == theme }
        let info = themeInfo[theme] ?? ("🎯", theme.capitalized)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    selectedTheme = nil
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appTextSecondary)
                }
                .accessibilityLabel("Back to themes")
                Text("\(info.emoji) \(info.name)")
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }
            .padding(.horizontal, AppTheme.standardPadding)
            .padding(.top, AppTheme.standardPadding)
            .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(themePacks) { meta in
                        packRow(meta: meta)
                        if meta.id != themePacks.last?.id {
                            Divider().padding(.leading, AppTheme.standardPadding)
                        }
                    }
                }
            }
            .frame(maxHeight: 260)
            .padding(.bottom, 8)
        }
    }

    private func packRow(meta: CrosswordPackMeta) -> some View {
        Button { startPackGame(meta: meta) } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meta.title)
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                    Text("\(meta.difficulty.capitalized) · \(meta.puzzleCount) puzzles")
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, AppTheme.standardPadding)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play \(meta.title)")
    }

    // MARK: - Legacy difficulty sheet (fallback when no packs)

    private var difficultySheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEW GAME")
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal, AppTheme.standardPadding)
                .padding(.top, AppTheme.standardPadding)
                .padding(.bottom, 8)

            ForEach(CrosswordDifficulty.allCases.filter { $0 == .mini || $0 == .standard }) { difficulty in
                Button { startNewGame(difficulty: difficulty) } label: {
                    HStack(spacing: 16) {
                        Image(systemName: difficulty == .mini
                              ? "square.grid.3x3.square" : "square.grid.4x3.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.appTextPrimary)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(difficulty.displayName)
                                .font(.appBody)
                                .foregroundColor(.appTextPrimary)
                            Text(difficulty == .mini
                                 ? "Quick 5 min solve"
                                 : "Classic 9×9 challenge")
                                .font(.appCaption)
                                .foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.standardPadding)
                    .padding(.vertical, 18)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start \(difficulty.displayName) game")

                if difficulty == .mini {
                    Divider().padding(.leading, AppTheme.standardPadding + 48)
                }
            }
        }
        .background(Color.appCard)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -4)
    }

    // MARK: - Actions

    private func startPackGame(meta: CrosswordPackMeta) {
        // Load a puzzle from the pack and navigate
        guard let pack = puzzleBank.getPack(id: meta.packId),
              let packPuzzle = pack.puzzles.randomElement() else { return }
        let puzzle = packPuzzle.toCrosswordPuzzle(packId: meta.packId)
        persistence.save(puzzle, key: PersistenceService.Keys.crosswordPendingPuzzle)
        router.navigate(to: .gamePlay(gameId: "crossword", context: meta.packId))
    }

    private func startNewGame(difficulty: CrosswordDifficulty) {
        guard let puzzle = puzzleBank.getPuzzle(for: difficulty) else { return }
        persistence.save(puzzle, key: PersistenceService.Keys.crosswordPendingPuzzle)
        router.navigate(to: .gamePlay(gameId: "crossword", context: difficulty.rawValue))
    }

    private func startDailyChallenge() {
        let puzzle = crosswordDailyChallenge.todayPuzzle(bank: puzzleBank)
        persistence.save(puzzle, key: PersistenceService.Keys.crosswordPendingPuzzle)
        persistence.save(true, key: PersistenceService.Keys.crosswordPendingIsDailyChallenge)
        router.navigate(to: .gamePlay(gameId: "crossword", context: "daily"))
    }

    private func resumeSavedGame(difficulty: CrosswordDifficulty) {
        guard let state = persistence.load(CrosswordGameState.self,
                                           key: PersistenceService.Keys.crosswordActiveGame) else { return }
        persistence.save(state.puzzle, key: PersistenceService.Keys.crosswordPendingPuzzle)
        router.navigate(to: .gamePlay(gameId: "crossword", context: difficulty.rawValue))
    }

    private func clearSavedGame() {
        persistence.delete(key: PersistenceService.Keys.crosswordActiveGame)
        hasSavedGame = false
        savedDifficulty = nil
    }

    private func checkSavedGame() {
        if let state = persistence.load(CrosswordGameState.self,
                                        key: PersistenceService.Keys.crosswordActiveGame) {
            hasSavedGame = true
            savedDifficulty = state.puzzle.difficulty
        }
    }
}

// MARK: - Selective corner radius helper (local to avoid collision with SudokuLobbyView)

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(CrosswordRoundedCorner(radius: radius, corners: corners))
    }
}

private struct CrosswordRoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}
