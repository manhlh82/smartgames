import Foundation
import Combine

/// All possible game phases.
enum GamePhase: Equatable {
    case playing
    case paused
    case won
    case lost
    case needsHintAd
    case needsMistakeResetAd
}

/// Visual highlight state for a Sudoku cell.
enum CellHighlightState {
    case normal
    case selected       // the tapped cell (filled)
    case selectedEmpty  // the tapped cell (empty — yellow)
    case related        // same row/col/box
    case sameNumber     // contains the same digit as selected
    case error          // wrong placement
}

/// Manages all Sudoku game logic, state, and coordination with services.
@MainActor
final class SudokuGameViewModel: ObservableObject {
    // MARK: - Published State
    @Published var puzzle: SudokuPuzzle
    @Published var selectedCell: CellPosition?
    @Published var isPencilMode: Bool = false
    @Published var gamePhase: GamePhase = .playing
    @Published var elapsedSeconds: Int = 0
    @Published var mistakeCount: Int = 0
    @Published var hintsRemaining: Int
    @Published var hintsUsedTotal: Int = 0
    @Published private(set) var undoStack: [BoardSnapshot] = []
    @Published var lastCompletedNumber: Int?
    @Published var mistakeResetUsesThisLevel: Int = 0

    // MARK: - Services
    let persistence: PersistenceService
    let analytics: AnalyticsService
    let sound: SoundService
    let haptics: HapticsService
    let ads: AdsService
    let statisticsService: StatisticsService
    let gameCenterService: GameCenterService
    /// Non-nil only when this game is today's daily challenge.
    let dailyChallengeService: DailyChallengeService?
    /// Optional StoreService — when provided, observes hint pack purchases.
    weak var storeService: StoreService? {
        didSet { observeHintGrants() }
    }
    /// Per-game monetization settings.
    let monetizationConfig: MonetizationConfig

    private var timerTask: Task<Void, Never>?
    private var hintGrantTask: Task<Void, Never>?
    private let validator = SudokuValidator()
    private let maxUndoDepth = 50
    private var autoSaveTask: Task<Void, Never>?

    var mistakeLimit: Int { puzzle.difficulty.mistakeLimit }
    var isUndoAvailable: Bool { !undoStack.isEmpty }

    /// True when erase has something to clear — used to visually disable the Erase button.
    var isEraseAvailable: Bool {
        guard let pos = selectedCell else { return false }
        let cell = puzzle.board[pos.row][pos.col]
        return !cell.isGiven && (cell.value != nil || !cell.pencilMarks.isEmpty)
    }

    /// Numbers fully placed (all 9 of that digit on board) — used to dim number pad.
    var completedNumbers: Set<Int> {
        var counts = [Int: Int]()
        for row in puzzle.board {
            for cell in row {
                if let v = cell.value { counts[v, default: 0] += 1 }
            }
        }
        return Set(counts.filter { $0.value == 9 }.keys)
    }

    // MARK: - Init
    init(puzzle: SudokuPuzzle, persistence: PersistenceService, analytics: AnalyticsService,
         sound: SoundService, haptics: HapticsService, ads: AdsService,
         statisticsService: StatisticsService, gameCenterService: GameCenterService,
         dailyChallengeService: DailyChallengeService? = nil,
         monetizationConfig: MonetizationConfig = MonetizationConfig()) {
        self.puzzle = puzzle
        self.persistence = persistence
        self.analytics = analytics
        self.sound = sound
        self.haptics = haptics
        self.ads = ads
        self.statisticsService = statisticsService
        self.gameCenterService = gameCenterService
        self.dailyChallengeService = dailyChallengeService
        self.monetizationConfig = monetizationConfig
        self.hintsRemaining = persistence.load(Int.self, key: PersistenceService.Keys.sudokuHintsRemaining)
                              ?? puzzle.difficulty.freeHints
        startTimer()
        analytics.log(.sudokuGameStarted(difficulty: puzzle.difficulty.rawValue, isResume: false))
    }

    // MARK: - Cell Selection
    func selectCell(row: Int, col: Int) {
        selectedCell = CellPosition(row: row, col: col)
        haptics.selection()
    }

    // MARK: - Highlight States
    func highlightState(for row: Int, col: Int) -> CellHighlightState {
        let cell = puzzle.board[row][col]
        guard let selected = selectedCell else { return cell.hasError ? .error : .normal }
        let pos = CellPosition(row: row, col: col)

        if selected == pos {
            return cell.value == nil ? .selectedEmpty : .selected
        }
        if cell.hasError { return .error }

        // Same number highlight
        if let selValue = puzzle.board[selected.row][selected.col].value,
           let cellValue = cell.value, selValue == cellValue {
            return .sameNumber
        }
        // Related cell (same row, col, or box)
        if SudokuBoardUtils.peers(for: selected.row, col: selected.col).contains(pos) {
            return .related
        }
        return .normal
    }

    // MARK: - Number Input
    func placeNumber(_ n: Int) {
        guard let pos = selectedCell else { return }
        let cell = puzzle.board[pos.row][pos.col]
        guard !cell.isGiven else { return }

        if isPencilMode {
            if puzzle.board[pos.row][pos.col].pencilMarks.contains(n) {
                puzzle.board[pos.row][pos.col].pencilMarks.remove(n)
            } else {
                puzzle.board[pos.row][pos.col].pencilMarks.insert(n)
            }
            haptics.impact(.light)
            scheduleAutoSave()
            return
        }

        pushSnapshot()

        let wasCompleted = completedNumbers.contains(n)
        let isCorrect = n == puzzle.solution[pos.row][pos.col]
        puzzle.board[pos.row][pos.col].value = n
        puzzle.board[pos.row][pos.col].pencilMarks = []
        puzzle.board[pos.row][pos.col].hasError = !isCorrect

        if isCorrect {
            clearPencilMarks(value: n, peers: SudokuBoardUtils.peers(for: pos.row, col: pos.col))
            sound.playTap()
            haptics.impact(.medium)
            analytics.log(.sudokuNumberPlaced(difficulty: puzzle.difficulty.rawValue,
                isCorrect: true, elapsedSeconds: elapsedSeconds))
            // Trigger completion pulse when a number reaches all 9 placements
            if !wasCompleted && completedNumbers.contains(n) {
                lastCompletedNumber = n
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    self?.lastCompletedNumber = nil
                }
            }
            checkWin()
        } else {
            mistakeCount += 1
            sound.playError()
            haptics.notification(.error)
            analytics.log(.sudokuNumberPlaced(difficulty: puzzle.difficulty.rawValue,
                isCorrect: false, elapsedSeconds: elapsedSeconds))
            if mistakeCount >= mistakeLimit {
                gamePhase = .lost
                stopTimer()
                statisticsService.recordLoss(difficulty: puzzle.difficulty)
                analytics.log(.sudokuGameFailed(difficulty: puzzle.difficulty.rawValue,
                    elapsedSeconds: elapsedSeconds, mistakes: mistakeCount))
            }
            // Auto-clear incorrect value after 1.5s to reduce friction
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard let self, self.puzzle.board[pos.row][pos.col].hasError else { return }
                self.puzzle.board[pos.row][pos.col].value = nil
                self.puzzle.board[pos.row][pos.col].hasError = false
                self.scheduleAutoSave()
            }
        }
        scheduleAutoSave()
    }

    // MARK: - Erase
    func eraseSelected() {
        guard let pos = selectedCell else { return }
        guard !puzzle.board[pos.row][pos.col].isGiven else { return }
        pushSnapshot()
        puzzle.board[pos.row][pos.col].value = nil
        puzzle.board[pos.row][pos.col].pencilMarks = []
        puzzle.board[pos.row][pos.col].hasError = false
        haptics.impact(.light)
        analytics.log(.sudokuEraserUsed(difficulty: puzzle.difficulty.rawValue))
        scheduleAutoSave()
    }

    // MARK: - Undo
    func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        puzzle.board = snapshot.board
        mistakeCount = snapshot.mistakeCount
        haptics.impact(.light)
        analytics.log(.sudokuUndoUsed(difficulty: puzzle.difficulty.rawValue))
        scheduleAutoSave()
    }

    // MARK: - Hint

    /// True when hints are below cap and an ad can be offered to earn more.
    var canWatchAdForHints: Bool {
        hintsRemaining < monetizationConfig.maxHintCap
    }

    func useHint() {
        guard gamePhase == .playing else { return }
        if hintsRemaining > 0 {
            applyHint()
        } else {
            // Only offer ad if hints are below cap (cap may be exceeded from IAP)
            if canWatchAdForHints {
                gamePhase = .needsHintAd
            }
            analytics.log(.sudokuHintExhausted(difficulty: puzzle.difficulty.rawValue))
        }
    }

    func grantHintsAfterAd() {
        let granted = grantHints(monetizationConfig.rewardedHintAmount)
        gamePhase = .playing
        if granted > 0 {
            analytics.log(.hintEarnedFromAd(
                difficulty: puzzle.difficulty.rawValue,
                hintsAfter: hintsRemaining
            ))
            applyHint()
        }
    }

    func cancelHintAd() {
        gamePhase = .playing
    }

    // MARK: - Mistake Reset

    /// True when the mistake reset feature is available for use.
    var canResetMistakes: Bool {
        mistakeCount > 0
        && gamePhase == .playing
        && monetizationConfig.mistakeResetEnabled
        && mistakeResetUsesThisLevel < monetizationConfig.mistakeResetUsesPerLevel
    }

    /// Request a mistake reset — transitions to .needsMistakeResetAd to trigger ad prompt.
    func requestMistakeReset() {
        guard canResetMistakes else { return }
        gamePhase = .needsMistakeResetAd
        analytics.log(.mistakeResetPromptShown(
            difficulty: puzzle.difficulty.rawValue,
            mistakeCount: mistakeCount
        ))
    }

    /// Called after ad successfully completes — resets mistakes to 0.
    func grantMistakeResetAfterAd() {
        mistakeCount = 0
        mistakeResetUsesThisLevel += 1
        gamePhase = .playing
        scheduleAutoSave()
        analytics.log(.mistakeResetUsed(
            difficulty: puzzle.difficulty.rawValue,
            usesThisLevel: mistakeResetUsesThisLevel
        ))
    }

    /// Called when user cancels the mistake reset ad prompt.
    func cancelMistakeResetAd() {
        gamePhase = .playing
        analytics.log(.mistakeResetDeclined(difficulty: puzzle.difficulty.rawValue))
    }

    /// Grants hints up to the configured cap. IAP grants bypass the cap (user paid real money).
    /// Returns the actual number of hints granted.
    @discardableResult
    private func grantHints(_ amount: Int, bypassCap: Bool = false) -> Int {
        let effectiveAmount: Int
        if bypassCap {
            effectiveAmount = amount
        } else {
            effectiveAmount = min(amount, monetizationConfig.maxHintCap - hintsRemaining)
        }
        guard effectiveAmount > 0 else {
            analytics.log(.hintCapReached(currentHints: hintsRemaining, maxCap: monetizationConfig.maxHintCap))
            return 0
        }
        hintsRemaining += effectiveAmount
        persistence.save(hintsRemaining, key: PersistenceService.Keys.sudokuHintsRemaining)
        return effectiveAmount
    }

    private func applyHint() {
        guard let pos = validator.suggestHint(puzzle.board, solution: puzzle.solution) else { return }
        pushSnapshot()
        let value = puzzle.solution[pos.row][pos.col]
        puzzle.board[pos.row][pos.col].value = value
        puzzle.board[pos.row][pos.col].pencilMarks = []
        puzzle.board[pos.row][pos.col].hasError = false
        hintsRemaining -= 1
        hintsUsedTotal += 1
        persistence.save(hintsRemaining, key: PersistenceService.Keys.sudokuHintsRemaining)
        selectedCell = pos
        sound.playHint()
        haptics.impact(.medium)
        analytics.log(.sudokuHintUsed(difficulty: puzzle.difficulty.rawValue,
            hintsRemainingBefore: hintsRemaining + 1))
        clearPencilMarks(value: value, peers: SudokuBoardUtils.peers(for: pos.row, col: pos.col))
        checkWin()
        scheduleAutoSave()
    }

    // MARK: - Remaining Counts (for number pad display)
    var remainingCounts: [Int: Int] {
        var counts = [Int: Int]()
        for n in 1...9 {
            let placed = puzzle.board.flatMap { $0 }.filter { $0.value == n }.count
            counts[n] = max(0, 9 - placed)
        }
        return counts
    }

    // MARK: - Pencil Mode
    func togglePencilMode() {
        isPencilMode.toggle()
        haptics.selection()
        analytics.log(.sudokuPencilModeToggled(enabled: isPencilMode))
    }

    /// Auto-fills all valid pencil mark candidates for every empty cell. Undoable.
    func autoFillPencilMarks() {
        pushSnapshot()
        for row in 0..<9 {
            for col in 0..<9 where puzzle.board[row][col].isEmpty {
                let used = SudokuBoardUtils.usedValues(in: puzzle.board, row: row, col: col)
                puzzle.board[row][col].pencilMarks = Set(1...9).subtracting(used)
            }
        }
        haptics.impact(.medium)
        scheduleAutoSave()
    }

    // MARK: - Pause / Resume
    func pause() {
        guard gamePhase == .playing else { return }
        gamePhase = .paused
        stopTimer()
        autoSave()
        analytics.log(.sudokuGamePaused(difficulty: puzzle.difficulty.rawValue,
            elapsedSeconds: elapsedSeconds))
    }

    func resume() {
        guard gamePhase == .paused else { return }
        gamePhase = .playing
        startTimer()
        analytics.log(.sudokuGameResumed(difficulty: puzzle.difficulty.rawValue))
    }

    /// Resumes game after a rewarded ad on the lose screen.
    /// Cannot use `resume()` here because gamePhase is `.lost`, not `.paused`.
    func continueAfterAd() {
        mistakeCount = mistakeLimit - 1
        gamePhase = .playing
        startTimer()
        scheduleAutoSave()
    }

    // MARK: - Restart
    func restart() {
        puzzle = SudokuPuzzle(id: puzzle.id, difficulty: puzzle.difficulty,
                              givens: puzzle.givens, solution: puzzle.solution)
        elapsedSeconds = 0
        mistakeCount = 0
        hintsUsedTotal = 0
        mistakeResetUsesThisLevel = 0
        undoStack = []
        selectedCell = nil
        gamePhase = .playing
        startTimer()
        analytics.log(.sudokuGameRestarted(difficulty: puzzle.difficulty.rawValue))
    }

    // MARK: - Win Check
    private func checkWin() {
        guard validator.isSolved(puzzle.board, solution: puzzle.solution) else { return }
        gamePhase = .won
        stopTimer()
        sound.playWin()
        haptics.notification(.success)
        statisticsService.recordWin(difficulty: puzzle.difficulty,
                                    elapsedSeconds: elapsedSeconds,
                                    mistakes: mistakeCount)
        // Mark daily challenge complete when applicable
        dailyChallengeService?.markCompleted(
            elapsedSeconds: elapsedSeconds,
            mistakes: mistakeCount,
            stars: starRating
        )
        // Submit score to Game Center only if this is a personal best
        let currentBest = statisticsService.stats(for: puzzle.difficulty).bestTimeSeconds
        if elapsedSeconds <= currentBest {
            gameCenterService.submitScore(elapsedSeconds, difficulty: puzzle.difficulty)
        }
        persistence.delete(key: PersistenceService.Keys.sudokuActiveGame)
        analytics.log(.sudokuGameCompleted(difficulty: puzzle.difficulty.rawValue,
            elapsedSeconds: elapsedSeconds, mistakes: mistakeCount,
            hintsUsed: hintsUsedTotal, stars: starRating))

        // Grant level-completion hint reward (capped at maxHintCap)
        let levelHintGranted = grantHints(monetizationConfig.levelCompleteHintReward)
        if levelHintGranted > 0 {
            analytics.log(.hintEarnedFromLevel(
                difficulty: puzzle.difficulty.rawValue,
                hintsAfter: hintsRemaining
            ))
        }

        // Configure interstitial frequency and show post-level ad if appropriate
        ads.interstitial.configure(frequency: monetizationConfig.interstitialFrequency)
        if monetizationConfig.interstitialEnabled
            && storeService?.hasRemovedAds != true
            && ads.interstitial.shouldShowAfterLevelComplete() {
            ads.showInterstitialIfReady()
        }
    }

    // MARK: - Star Rating
    var starRating: Int {
        if mistakeCount == 0 && elapsedSeconds < 300 { return 3 }
        if mistakeCount <= 1 && elapsedSeconds < 600 { return 2 }
        return 1
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

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Auto Save
    func autoSave() {
        var state = SudokuGameState(puzzle: puzzle, elapsedSeconds: elapsedSeconds,
                                   mistakeCount: mistakeCount, hintsRemaining: hintsRemaining,
                                   hintsUsedTotal: hintsUsedTotal, undoStack: undoStack)
        state.mistakeResetUsesThisLevel = mistakeResetUsesThisLevel
        persistence.save(state, key: PersistenceService.Keys.sudokuActiveGame)
    }

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.autoSave()
        }
    }

    // MARK: - Helpers
    private func pushSnapshot() {
        undoStack.append(BoardSnapshot(board: puzzle.board, mistakeCount: mistakeCount))
        if undoStack.count > maxUndoDepth { undoStack.removeFirst() }
    }

    private func clearPencilMarks(value: Int, peers: Set<CellPosition>) {
        for peer in peers {
            puzzle.board[peer.row][peer.col].pencilMarks.remove(value)
        }
    }

    // MARK: - Hint Grant (IAP)

    /// Grants 12 hints when a Hint Pack is purchased. Bypasses cap — user paid real money.
    /// Called via StoreService.pendingHintGrant.
    func grantHintsFromPurchase() {
        grantHints(12, bypassCap: true)
        analytics.log(.hintEarnedFromIAP(hintsAfter: hintsRemaining))
        // If game was waiting for an ad-based hint, resume automatically
        if gamePhase == .needsHintAd {
            gamePhase = .playing
            applyHint()
        }
    }

    /// Watches StoreService.pendingHintGrant — grants hints and resets the flag.
    private func observeHintGrants() {
        hintGrantTask?.cancel()
        guard let store = storeService else { return }
        hintGrantTask = Task { [weak self, weak store] in
            guard let store else { return }
            // Observe via polling (Combine not available on actor-isolated ObservableObject easily)
            var previous = store.pendingHintGrant
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                let current = store.pendingHintGrant
                if current && !previous {
                    self?.grantHintsFromPurchase()
                    store.pendingHintGrant = false
                }
                previous = current
            }
        }
    }

    deinit {
        timerTask?.cancel()
        autoSaveTask?.cancel()
        hintGrantTask?.cancel()
    }
}
