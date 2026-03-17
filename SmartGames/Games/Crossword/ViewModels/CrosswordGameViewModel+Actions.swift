import Foundation

/// Actions extension — cell selection, input, hints, undo, pause/resume/restart, win check, cursor nav.
extension CrosswordGameViewModel {

    // MARK: - Cell Selection

    func selectCell(row: Int, col: Int) {
        guard row < puzzle.size, col < puzzle.size else { return }
        guard !boardState.cells[row][col].isBlack else { return }
        if selectedRow == row && selectedCol == col {
            // Toggle direction on re-tap
            selectedDirection = selectedDirection == .across ? .down : .across
        } else {
            selectedRow = row
            selectedCol = col
            // Auto-determine best direction based on clue membership
            if !hasClue(row: row, col: col, direction: selectedDirection) {
                let other: ClueDirection = selectedDirection == .across ? .down : .across
                if hasClue(row: row, col: col, direction: other) {
                    selectedDirection = other
                }
            }
        }
        haptics.selection()
    }

    // MARK: - Letter Input

    func inputLetter(_ char: Character) {
        guard gamePhase == .playing,
              let row = selectedRow, let col = selectedCol else { return }
        let cell = boardState.cells[row][col]
        guard !cell.isBlack && !cell.isRevealed else {
            advanceCursor()
            return
        }
        pushSnapshot()
        boardState.cells[row][col].userEntry = Character(String(char).uppercased())
        haptics.impact(.light)
        sound.playTap()
        scheduleAutoSave()
        advanceCursor()
        checkWin()
    }

    func deleteLetter() {
        guard gamePhase == .playing,
              let row = selectedRow, let col = selectedCol else { return }
        let cell = boardState.cells[row][col]
        if !cell.isBlack && !cell.isRevealed && cell.userEntry != nil {
            pushSnapshot()
            boardState.cells[row][col].userEntry = nil
            haptics.impact(.light)
            scheduleAutoSave()
        } else {
            retreatCursor()
        }
    }

    // MARK: - Undo (FREE)

    func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        boardState.cells = snapshot.cells
        haptics.impact(.light)
        analytics.log(.crosswordUndoUsed(difficulty: puzzle.difficulty.rawValue))
        scheduleAutoSave()
    }

    // MARK: - Hints

    func checkLetter() {
        guard gamePhase == .playing, hintsRemaining > 0,
              let row = selectedRow, let col = selectedCol else {
            if hintsRemaining == 0 && canWatchAdForHints { gamePhase = .needsHintAd }
            return
        }
        hintsRemaining -= 1
        hintsUsedTotal += 1
        persistence.save(hintsRemaining, key: PersistenceService.Keys.crosswordHintsRemaining)
        let correct = validator.isLetterCorrect(row: row, col: col, board: boardState, puzzle: puzzle)
        checkFeedbackCell = (row: row, col: col, correct: correct)
        analytics.log(.crosswordHintUsed(type: "check_letter", difficulty: puzzle.difficulty.rawValue))
        haptics.impact(.medium)
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self?.checkFeedbackCell = nil
        }
        scheduleAutoSave()
    }

    func revealLetter() {
        guard gamePhase == .playing, hintsRemaining > 0,
              let row = selectedRow, let col = selectedCol else {
            if hintsRemaining == 0 && canWatchAdForHints { gamePhase = .needsHintAd }
            return
        }
        guard !boardState.cells[row][col].isBlack,
              !boardState.cells[row][col].isRevealed,
              let solution = boardState.cells[row][col].solutionChar else { return }
        pushSnapshot()
        hintsRemaining -= 1
        hintsUsedTotal += 1
        persistence.save(hintsRemaining, key: PersistenceService.Keys.crosswordHintsRemaining)
        boardState.cells[row][col].userEntry = solution
        boardState.cells[row][col].isRevealed = true
        analytics.log(.crosswordHintUsed(type: "reveal_letter", difficulty: puzzle.difficulty.rawValue))
        haptics.impact(.medium)
        sound.playHint()
        scheduleAutoSave()
        advanceCursor()
        checkWin()
    }

    func revealWord() {
        guard gamePhase == .playing, hintsRemaining >= 3,
              let clue = activeClue else {
            if hintsRemaining < 3 && canWatchAdForHints { gamePhase = .needsHintAd }
            return
        }
        let cells = validator.wordCells(for: clue)
        let unrevealed = cells.filter { !boardState.cells[$0.row][$0.col].isRevealed }
        guard !unrevealed.isEmpty else { return }
        pushSnapshot()
        hintsRemaining -= 3
        hintsUsedTotal += 1
        persistence.save(hintsRemaining, key: PersistenceService.Keys.crosswordHintsRemaining)
        for pos in cells {
            guard let sol = boardState.cells[pos.row][pos.col].solutionChar else { continue }
            boardState.cells[pos.row][pos.col].userEntry = sol
            boardState.cells[pos.row][pos.col].isRevealed = true
        }
        analytics.log(.crosswordHintUsed(type: "reveal_word", difficulty: puzzle.difficulty.rawValue))
        haptics.impact(.medium)
        sound.playHint()
        scheduleAutoSave()
        checkWin()
    }

    func revealLetterWithDiamond() {
        guard gamePhase == .playing,
              let row = selectedRow, let col = selectedCol,
              !boardState.cells[row][col].isBlack,
              !boardState.cells[row][col].isRevealed else { return }
        guard diamondService.spend(amount: DiamondReward.undoCost) else { return }
        analytics.log(.crosswordDiamondHintUsed(difficulty: puzzle.difficulty.rawValue))
        analytics.log(.diamondSpent(amount: DiamondReward.undoCost,
                                    reason: "crossword_reveal_letter",
                                    balanceAfter: diamondService.balance))
        guard let solution = boardState.cells[row][col].solutionChar else { return }
        pushSnapshot()
        boardState.cells[row][col].userEntry = solution
        boardState.cells[row][col].isRevealed = true
        haptics.impact(.medium)
        sound.playHint()
        scheduleAutoSave()
        advanceCursor()
        checkWin()
    }

    func grantHintsAfterAd() {
        let cap = monetizationConfig.maxHintCap
        let grant = min(monetizationConfig.rewardedHintAmount, max(0, cap - hintsRemaining))
        if grant > 0 {
            hintsRemaining += grant
            persistence.save(hintsRemaining, key: PersistenceService.Keys.crosswordHintsRemaining)
        }
        gamePhase = .playing
    }

    func cancelHintAd() { gamePhase = .playing }

    // MARK: - Pause / Resume / Restart

    func pause() {
        guard gamePhase == .playing else { return }
        gamePhase = .paused
        stopTimer()
        autoSave()
    }

    func resume() {
        guard gamePhase == .paused else { return }
        gamePhase = .playing
        startTimer()
    }

    func restart() {
        boardState = CrosswordBoardState(from: puzzle)
        elapsedSeconds = 0
        hintsUsedTotal = 0
        undoStack = []
        selectedRow = nil
        selectedCol = nil
        checkFeedbackCell = nil
        hintsGrantedOnWin = 0
        goldEarnedOnWin = 0
        gamePhase = .playing
        startTimer()
    }

    // MARK: - Win Check

    func checkWin() {
        guard validator.isSolved(board: boardState, puzzle: puzzle) else { return }
        gamePhase = .won
        stopTimer()
        sound.playWin()
        haptics.notification(.success)
        persistence.delete(key: PersistenceService.Keys.crosswordActiveGame)

        dailyChallengeService?.markCompleted(
            timeSeconds: elapsedSeconds,
            hintsUsed: hintsUsedTotal,
            stars: starRating
        )

        analytics.log(.crosswordCompleted(
            difficulty: puzzle.difficulty.rawValue,
            hintsUsed: hintsUsedTotal,
            timeSeconds: elapsedSeconds
        ))

        // Grant level-complete hint reward
        if monetizationConfig.levelCompleteHintReward > 0 {
            let cap = monetizationConfig.maxHintCap
            let grant = min(monetizationConfig.levelCompleteHintReward, max(0, cap - hintsRemaining))
            if grant > 0 {
                hintsRemaining += grant
                persistence.save(hintsRemaining, key: PersistenceService.Keys.crosswordHintsRemaining)
                hintsGrantedOnWin = grant
            }
        }

        // Grant gold reward
        let baseGold = EconomyConfig.levelCompleteGold(game: "crossword",
                                                        difficulty: puzzle.difficulty.rawValue)
        let bonusGold = starRating >= 3 ? 10 : 0
        let totalGold = baseGold + bonusGold
        goldEarnedOnWin = totalGold
        goldService.earn(amount: totalGold)
        analytics.log(.goldEarned(amount: totalGold, source: "crossword",
                                  balanceAfter: goldService.balance))

        // Show interstitial
        ads.interstitial.configure(frequency: monetizationConfig.interstitialFrequency)
        if monetizationConfig.interstitialEnabled {
            ads.showInterstitialIfReady()
        }
    }

    // MARK: - Cursor Navigation

    func advanceCursor() {
        guard let row = selectedRow, let col = selectedCol,
              let clue = activeClue else { return }
        let cells = validator.wordCells(for: clue)
        guard let currentIdx = cells.firstIndex(where: { $0.row == row && $0.col == col })
        else { return }
        // Find next unfilled, unrevealed cell in word
        for i in (currentIdx + 1)..<cells.count {
            let pos = cells[i]
            if !boardState.cells[pos.row][pos.col].isRevealed
               && boardState.cells[pos.row][pos.col].userEntry == nil {
                selectedRow = pos.row
                selectedCol = pos.col
                return
            }
        }
        // Wrap to first empty cell in word
        for i in 0..<currentIdx {
            let pos = cells[i]
            if !boardState.cells[pos.row][pos.col].isRevealed
               && boardState.cells[pos.row][pos.col].userEntry == nil {
                selectedRow = pos.row
                selectedCol = pos.col
                return
            }
        }
    }

    func retreatCursor() {
        guard let row = selectedRow, let col = selectedCol,
              let clue = activeClue else { return }
        let cells = validator.wordCells(for: clue)
        guard let currentIdx = cells.firstIndex(where: { $0.row == row && $0.col == col })
        else { return }
        for i in stride(from: currentIdx - 1, through: 0, by: -1) {
            let pos = cells[i]
            if !boardState.cells[pos.row][pos.col].isRevealed {
                selectedRow = pos.row
                selectedCol = pos.col
                if boardState.cells[pos.row][pos.col].userEntry != nil {
                    pushSnapshot()
                    boardState.cells[pos.row][pos.col].userEntry = nil
                    scheduleAutoSave()
                }
                return
            }
        }
    }
}
