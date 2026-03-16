import Foundation

/// Drop Rush audio asset configuration.
/// File names without extension — SoundService tries .caf then .mp3.
/// Actual audio files are added in Phase 06; names are wired here from day 1.
struct DropRushAudioConfig: AudioConfig {
    var backgroundMusicFileName: String? = "dropRush-bgm"
    var cellTapSFX: String?              = "dropRush-hit"
    var subgridCompleteSFX: String?      = nil   // concept unused in Drop Rush
    var puzzleCompleteSFX: String?       = "dropRush-level-complete"
}
