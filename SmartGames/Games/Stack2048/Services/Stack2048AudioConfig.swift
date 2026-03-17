import Foundation

/// Audio asset configuration for Stack 2048.
/// SFX are played by name via SoundService.playSFX(_:) — files load on demand, fail gracefully.
struct Stack2048AudioConfig: AudioConfig {
    var backgroundMusicFileName: String? = nil   // no background music
    var cellTapSFX: String?                      = nil
    var subgridCompleteSFX: String?              = nil
    var puzzleCompleteSFX: String?               = nil
}
