import Foundation
import AVFoundation
import Combine

/// Manages sound effects and background music.
/// Sound files live in Resources/Sounds/ as .caf or .mp3.
/// All playback is gated by SettingsService — wire via configure(settings:).
final class SoundService: ObservableObject {
    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var settingsService: SettingsService?
    private var cancellables = Set<AnyCancellable>()

    enum SoundEffect: String, CaseIterable {
        case tap = "tap"
        case error = "error"
        case win = "win"
        case hint = "hint"
        case subgridComplete = "subgrid-complete"
    }

    init() {
        preloadSounds()
    }

    /// Inject settings service after init to avoid circular dependency.
    func configure(settings: SettingsService) {
        self.settingsService = settings
        // React to music toggle immediately
        settings.$isMusicEnabled
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                if enabled { self?.resumeBackgroundMusic() }
                else { self?.pauseBackgroundMusic() }
            }
            .store(in: &cancellables)
    }

    // MARK: - Background Music

    /// Starts looping background music. No-op if already playing.
    func startBackgroundMusic(fileName: String) {
        guard settingsService?.isMusicEnabled ?? true else { return }
        guard musicPlayer == nil else { return }
        guard let url = audioURL(named: fileName) else { return }
        musicPlayer = try? AVAudioPlayer(contentsOf: url)
        musicPlayer?.numberOfLoops = -1
        musicPlayer?.volume = 0.45
        musicPlayer?.prepareToPlay()
        musicPlayer?.play()
    }

    func stopBackgroundMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    func pauseBackgroundMusic() {
        musicPlayer?.pause()
    }

    func resumeBackgroundMusic() {
        guard settingsService?.isMusicEnabled ?? true else { return }
        musicPlayer?.play()
    }

    // MARK: - Named SFX

    /// Plays a named SFX file — nil-safe (no-op). Uses preloaded players when available.
    func playSFX(_ fileName: String?) {
        guard let fileName else { return }
        guard settingsService?.isSoundEnabled ?? true else { return }
        if let sfx = SoundEffect(rawValue: fileName) {
            players[sfx]?.currentTime = 0
            players[sfx]?.play()
        } else {
            // On-demand load for sounds not in the preloaded set
            guard let url = audioURL(named: fileName) else { return }
            let player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        }
    }

    // MARK: - Legacy Convenience Methods

    func playTap()   { play(.tap) }
    func playError() { play(.error) }
    func playWin()   { play(.win) }
    func playHint()  { play(.hint) }

    // MARK: - Private

    private func play(_ effect: SoundEffect) {
        guard settingsService?.isSoundEnabled ?? true else { return }
        players[effect]?.currentTime = 0
        players[effect]?.play()
    }

    private func preloadSounds() {
        for effect in SoundEffect.allCases {
            guard let url = audioURL(named: effect.rawValue) else { continue }
            players[effect] = try? AVAudioPlayer(contentsOf: url)
            players[effect]?.prepareToPlay()
        }
    }

    /// Resolves audio URL — tries .caf, .mp3, .m4a in order.
    private func audioURL(named fileName: String) -> URL? {
        Bundle.main.url(forResource: fileName, withExtension: "caf")
            ?? Bundle.main.url(forResource: fileName, withExtension: "mp3")
            ?? Bundle.main.url(forResource: fileName, withExtension: "m4a")
    }
}
