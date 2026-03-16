/// Per-game audio asset configuration.
/// SoundService is agnostic to game logic — games supply asset file names only.
/// File names should be provided without extension (SoundService tries .caf then .mp3).
protocol AudioConfig {
    /// Looping background music file name. nil = no background music for this game.
    var backgroundMusicFileName: String? { get }
    /// Cell selection tap SFX name. nil = silent.
    var cellTapSFX: String? { get }
    /// 3×3 subgrid completion SFX name. nil = silent.
    var subgridCompleteSFX: String? { get }
    /// Full puzzle completion SFX name. nil = use default win sound.
    var puzzleCompleteSFX: String? { get }
}
