import Foundation
import AVFoundation

/// Plays sound effects using pre-loaded AVAudioPlayer instances.
/// Sound files should be added to Resources/Sounds/ as .caf or .mp3.
final class SoundService: ObservableObject {
    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var settingsService: SettingsService?

    enum SoundEffect: String, CaseIterable {
        case tap = "tap"
        case error = "error"
        case win = "win"
        case hint = "hint"
    }

    init() {
        preloadSounds()
    }

    /// Inject settings service after init to avoid circular dependency.
    func configure(settings: SettingsService) {
        self.settingsService = settings
    }

    func playTap() { play(.tap) }
    func playError() { play(.error) }
    func playWin() { play(.win) }
    func playHint() { play(.hint) }

    private func play(_ effect: SoundEffect) {
        guard settingsService?.isSoundEnabled ?? true else { return }
        players[effect]?.currentTime = 0
        players[effect]?.play()
    }

    private func preloadSounds() {
        for effect in SoundEffect.allCases {
            // Try .caf first, then .mp3
            let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "caf")
                   ?? Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3")
            guard let url else { continue }
            players[effect] = try? AVAudioPlayer(contentsOf: url)
            players[effect]?.prepareToPlay()
        }
    }
}
