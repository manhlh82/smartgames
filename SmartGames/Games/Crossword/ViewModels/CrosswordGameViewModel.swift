import Foundation
import Combine

/// Main crossword game state machine.
/// Phases: playing ↔ paused → won | needsHintAd
@MainActor
final class CrosswordGameViewModel: ObservableObject {
    // MARK: - Published State
    @Published var puzzle: CrosswordPuzzle
    @Published var boardState: CrosswordBoardState
    @Published var selectedRow: Int? = nil
    @Published var selectedCol: Int? = nil
    @Published var selectedDirection: ClueDirection = .across
    @Published var gamePhase: GamePhase = .playing
    @Published var elapsedSeconds: Int = 0
    @Published var hintsRemaining: Int
    @Published var hintsUsedTotal: Int = 0
    @Published var undoStack: [CrosswordBoardSnapshot] = []
    @Published var hintsGrantedOnWin: Int = 0
    @Published var goldEarnedOnWin: Int = 0
    /// Cell currently showing check feedback. nil = none.
    @Published var checkFeedbackCell: (row: Int, col: Int, correct: Bool)? = nil

    // MARK: - Services
    let persistence: PersistenceService
    let analytics: AnalyticsService
    let sound: SoundService
    let haptics: HapticsService
    let ads: AdsService
    let goldService: GoldService
    let diamondService: DiamondService
    let monetizationConfig: MonetizationConfig
    let dailyChallengeService: CrosswordDailyChallengeService?
    let gameCenterService: GameCenterService

    let validator = CrosswordValidator()
    let maxUndoDepth = 20
    var timerTask: Task<Void, Never>?
    var autoSaveTask: Task<Void, Never>?

    var isUndoAvailable: Bool { !undoStack.isEmpty }
    var activeClue: CrosswordClue? { clue(at: selectedRow, col: selectedCol, direction: selectedDirection) }
    var canWatchAdForHints: Bool { hintsRemaining < monetizationConfig.maxHintCap }

    // MARK: - Init
    init(puzzle: CrosswordPuzzle,
         persistence: PersistenceService,
         analytics: AnalyticsService,
         sound: SoundService,
         haptics: HapticsService,
         ads: AdsService,
         goldService: GoldService,
         diamondService: DiamondService,
         monetizationConfig: MonetizationConfig = MonetizationConfig(),
         dailyChallengeService: CrosswordDailyChallengeService? = nil,
         gameCenterService: GameCenterService) {
        self.persistence = persistence
        self.analytics = analytics
        self.sound = sound
        self.haptics = haptics
        self.ads = ads
        self.goldService = goldService
        self.diamondService = diamondService
        self.monetizationConfig = monetizationConfig
        self.dailyChallengeService = dailyChallengeService
        self.gameCenterService = gameCenterService

        // Restore saved state if same puzzle
        if let saved = persistence.load(CrosswordGameState.self,
                                        key: PersistenceService.Keys.crosswordActiveGame),
           saved.puzzle.id == puzzle.id {
            self.puzzle = saved.puzzle
            self.boardState = saved.boardState
            self.elapsedSeconds = saved.elapsedSeconds
            self.hintsRemaining = saved.hintsRemaining
            self.hintsUsedTotal = saved.hintsUsedTotal
            self.undoStack = saved.undoStack
        } else {
            self.puzzle = puzzle
            self.boardState = CrosswordBoardState(from: puzzle)
            self.hintsRemaining = persistence.load(Int.self,
                key: PersistenceService.Keys.crosswordHintsRemaining) ?? puzzle.freeHints
        }
        startTimer()
        analytics.log(.crosswordStarted(difficulty: puzzle.difficulty.rawValue))
    }

    // MARK: - Star Rating
    var starRating: Int {
        if hintsUsedTotal == 0 && elapsedSeconds < 180 { return 3 }
        if hintsUsedTotal <= 2 && elapsedSeconds < 600 { return 2 }
        return 1
    }

    // MARK: - Clue Helpers
    func isInSelectedWord(row: Int, col: Int) -> Bool {
        guard let clue = activeClue else { return false }
        return validator.wordCells(for: clue).contains { $0.row == row && $0.col == col }
    }

    func clue(at row: Int?, col: Int?, direction: ClueDirection) -> CrosswordClue? {
        guard let row = row, let col = col else { return nil }
        return puzzle.clues.first { c in
            c.direction == direction &&
            validator.wordCells(for: c).contains(where: { $0.row == row && $0.col == col })
        }
    }

    func hasClue(row: Int, col: Int, direction: ClueDirection) -> Bool {
        clue(at: row, col: col, direction: direction) != nil
    }

    // MARK: - Snapshot
    func pushSnapshot() {
        undoStack.append(CrosswordBoardSnapshot(cells: boardState.cells))
        if undoStack.count > maxUndoDepth { undoStack.removeFirst() }
    }

    // MARK: - Auto Save
    func autoSave() {
        let state = CrosswordGameState(
            puzzle: puzzle,
            boardState: boardState,
            elapsedSeconds: elapsedSeconds,
            hintsRemaining: hintsRemaining,
            hintsUsedTotal: hintsUsedTotal,
            undoStack: undoStack
        )
        persistence.save(state, key: PersistenceService.Keys.crosswordActiveGame)
    }

    func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.autoSave()
        }
    }

    // MARK: - Timer
    func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                self?.elapsedSeconds += 1
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    deinit {
        timerTask?.cancel()
        autoSaveTask?.cancel()
    }
}
