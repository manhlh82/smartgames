import Foundation

/// Engine event handling, milestone tracking, and game-end logic for Stack2048GameViewModel.
extension Stack2048GameViewModel {

    // MARK: - Engine Events

    func handleEngineEvent(_ event: Stack2048EngineEvent) {
        switch event {
        case .tilePlaced:
            sound.playSFX("stack2048-place")
            haptics.impact(.light)

        case .tileMerged(let column, let row, let newValue):
            let sfx = newValue >= 512 ? "stack2048-merge-big" : "stack2048-merge"
            sound.playSFX(sfx)
            haptics.impact(.medium)
            spawnMergeEffect(column: column, row: row, value: newValue)
            logMilestoneTileIfNeeded(newValue)

        case .gameOver:
            handleGameOver()
        }
    }

    // MARK: - Game End

    func handleGameOver() {
        phase = .gameOver
        sound.playSFX("stack2048-gameover")
        haptics.notification(.error)

        let score = gameState.score
        let maxTile = gameState.maxTileValue
        var progress = persistence.load(Stack2048Progress.self, key: PersistenceService.Keys.stack2048Progress) ?? Stack2048Progress()
        let wasHighScore = score > progress.highScore
        progress.recordResult(score: score, maxTile: maxTile)
        persistence.save(progress, key: PersistenceService.Keys.stack2048Progress)

        isNewHighScore = wasHighScore
        if wasHighScore { highScore = score }

        let base = GoldReward.stack2048GameOver
        let bonus = wasHighScore ? GoldReward.stack2048HighScoreBonus : 0
        let total = base + bonus
        goldEarnedOnEnd = total
        goldService.earn(amount: total)
        analytics.log(.goldEarned(amount: total, source: "stack2048", balanceAfter: goldService.balance))
        analytics.log(.stack2048GameOver(score: score, maxTile: maxTile, gamesPlayed: progress.gamesPlayed))
    }

    func handleWin() {
        hasWonThisSession = true
        phase = .won
        sound.playSFX("stack2048-win")
        haptics.notification(.success)
        let score = gameState.score
        var progress = persistence.load(Stack2048Progress.self, key: PersistenceService.Keys.stack2048Progress) ?? Stack2048Progress()
        progress.recordWin()
        persistence.save(progress, key: PersistenceService.Keys.stack2048Progress)
        goldService.earn(amount: GoldReward.stack2048Win)
        analytics.log(.goldEarned(amount: GoldReward.stack2048Win, source: "stack2048_win", balanceAfter: goldService.balance))
        analytics.log(.stack2048Win(score: score))
    }

    // MARK: - Helpers

    func spawnMergeEffect(column: Int, row: Int, value: Int) {
        let effect = MergeEffect(column: column, row: row, value: value)
        mergeEffects.append(effect)
        let eid = effect.id
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            mergeEffects.removeAll { $0.id == eid }
        }
    }

    func logMilestoneTileIfNeeded(_ value: Int) {
        let milestones: Set<Int> = [512, 1024, 2048, 4096]
        guard milestones.contains(value), !milestonesTileLogged.contains(value) else { return }
        milestonesTileLogged.insert(value)
        analytics.log(.stack2048MilestoneTile(value: value))
        if value == 2048, !hasWonThisSession {
            handleWin()
        }
    }
}
