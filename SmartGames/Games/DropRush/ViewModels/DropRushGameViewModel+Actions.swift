import Foundation

extension DropRushGameViewModel {

    /// Fire quit analytics — call before router.pop().
    func quit() {
        analytics.log(.dropRushQuit(level: levelNumber, elapsed: engine.state.elapsedTime))
    }

    /// Request a rewarded-ad continue after game over.
    /// Transitions to .watchingAd, restores 1 life on success, then resumes play.
    /// Limited to once per level attempt.
    func requestContinue() {
        guard phase == .gameOver, !continueUsedThisAttempt else { return }
        phase = .watchingAd
        continueAvailable = false
        ads.showRewardedAd(context: .continue) { [weak self] success in
            guard let self else { return }
            if success {
                self.applyContinue()
            } else {
                self.analytics.log(.dropRushContinueDeclined(level: self.levelNumber))
                self.phase = .gameOver
            }
        }
    }

    /// Spend 2 diamonds to get a full-hearts continue (no ad required).
    func requestDiamondContinue() {
        guard phase == .gameOver, !continueUsedThisAttempt else { return }
        guard diamondService.spend(amount: DiamondReward.continueFullReviveCost) else { return }
        analytics.log(.diamondSpent(amount: DiamondReward.continueFullReviveCost, reason: "continue_full_revive", balanceAfter: diamondService.balance))
        // Restore all lives (full revive)
        engine.restoreLife()
        engine.restoreLife()
        engine.restoreLife()
        applyContinue()
    }

    /// Shared continue state transition used by both ad-continue and diamond-continue.
    private func applyContinue() {
        continueUsedThisAttempt = true
        stars = 0
        isNewHighScore = false
        engine.restoreLife()
        engineState = engine.state
        analytics.log(.dropRushContinueUsed(level: levelNumber))
        lastTickDate = nil
        phase = .playing
    }
}
