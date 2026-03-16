/// Sudoku-specific audio asset configuration.
/// Asset file names map to files in Resources/Sounds/.
struct SudokuAudioConfig: AudioConfig {
    var backgroundMusicFileName: String? = "sudoku-ambient"
    var cellTapSFX: String?              = "tap"
    var subgridCompleteSFX: String?      = "subgrid-complete"
    var puzzleCompleteSFX: String?       = "win"
}
