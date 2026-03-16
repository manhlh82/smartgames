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
        ads.showRewardedAd { [weak self] success in
            guard let self else { return }
            if success {
                self.continueUsedThisAttempt = true
                self.stars = 0
                self.isNewHighScore = false
                self.engine.restoreLife()
                self.engineState = self.engine.state
                self.analytics.log(.dropRushContinueUsed(level: self.levelNumber))
                self.lastTickDate = nil
                self.phase = .playing
            } else {
                self.analytics.log(.dropRushContinueDeclined(level: self.levelNumber))
                self.phase = .gameOver
            }
        }
    }
}
