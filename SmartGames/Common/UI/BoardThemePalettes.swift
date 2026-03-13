import SwiftUI

// MARK: - Static Palettes (all 9 themes)

extension BoardTheme {

    // MARK: Free Themes

    /// Light theme — clean white board, classic iOS blue accents.
    static let light = BoardTheme(
        name: .light,
        boardBackground: Color(hex: "#F5F5F5"),
        cellBackground: Color.white,
        cellText: Color(hex: "#007AFF"),
        givenText: Color(hex: "#1C1C1E"),
        gridLine: Color(hex: "#C0C0C0"),
        thickGridLine: Color(hex: "#333333"),
        selectedCell: Color(hex: "#1565C0"),
        relatedCell: Color(hex: "#E3F2FD"),
        sameNumberCell: Color(hex: "#B2EBF2"),
        selectedEmptyCell: Color(hex: "#FFF9C4"),
        errorCell: Color(hex: "#FFEBEE"),
        pencilMarkText: Color.gray,
        numberPadButton: Color.white,
        numberPadText: Color(hex: "#007AFF"),
        cardBackground: Color.white
    )

    /// Dark theme — dark gray board, high-contrast blue text.
    static let dark = BoardTheme(
        name: .dark,
        boardBackground: Color(hex: "#1C1C1E"),
        cellBackground: Color(hex: "#2C2C2E"),
        cellText: Color(hex: "#64B5F6"),
        givenText: Color(hex: "#E0E0E0"),
        gridLine: Color(hex: "#555555"),
        thickGridLine: Color(hex: "#AAAAAA"),
        selectedCell: Color(hex: "#42A5F5"),
        relatedCell: Color(hex: "#1E3A5F"),
        sameNumberCell: Color(hex: "#1B3B3F"),
        selectedEmptyCell: Color(hex: "#3B3820"),
        errorCell: Color(hex: "#5C1A1A"),
        pencilMarkText: Color(hex: "#8E8E93"),
        numberPadButton: Color(hex: "#3A3A3C"),
        numberPadText: Color(hex: "#64B5F6"),
        cardBackground: Color(hex: "#2C2C2E")
    )

    // MARK: Paid Themes (50 coins)

    /// Cherry — deep red board with vibrant accent. 50 coins.
    static let cherry = BoardTheme(
        name: .cherry,
        boardBackground: Color(hex: "#2D0A0A"),
        cellBackground: Color(hex: "#3D1515"),
        cellText: Color(hex: "#FF6B6B"),
        givenText: Color(hex: "#FFD4D4"),
        gridLine: Color(hex: "#5C2020"),
        thickGridLine: Color(hex: "#8B3A3A"),
        selectedCell: Color(hex: "#E53935"),
        relatedCell: Color(hex: "#4A1010"),
        sameNumberCell: Color(hex: "#3B1818"),
        selectedEmptyCell: Color(hex: "#3D2020"),
        errorCell: Color(hex: "#6B1010"),
        pencilMarkText: Color(hex: "#CC8888"),
        numberPadButton: Color(hex: "#3D1515"),
        numberPadText: Color(hex: "#FF6B6B"),
        cardBackground: Color(hex: "#3D1515")
    )

    /// Brownish Calm (was Sepia) — warm tan and brown. 50 coins.
    static let brownishCalm = BoardTheme(
        name: .brownishCalm,
        boardBackground: Color(hex: "#F5E6D3"),
        cellBackground: Color(hex: "#FFF8F0"),
        cellText: Color(hex: "#795548"),
        givenText: Color(hex: "#4E342E"),
        gridLine: Color(hex: "#D7CCC8"),
        thickGridLine: Color(hex: "#8D6E63"),
        selectedCell: Color(hex: "#A1887F"),
        relatedCell: Color(hex: "#EFEBE9"),
        sameNumberCell: Color(hex: "#D7CCC8"),
        selectedEmptyCell: Color(hex: "#FFF9E6"),
        errorCell: Color(hex: "#FFCCBC"),
        pencilMarkText: Color(hex: "#A1887F"),
        numberPadButton: Color(hex: "#FFF8F0"),
        numberPadText: Color(hex: "#795548"),
        cardBackground: Color(hex: "#FFF8F0")
    )

    /// High Contrast — pure black/white with yellow accent. 50 coins.
    static let highContrast = BoardTheme(
        name: .highContrast,
        boardBackground: Color(hex: "#000000"),
        cellBackground: Color(hex: "#FFFFFF"),
        cellText: Color(hex: "#000000"),
        givenText: Color(hex: "#000000"),
        gridLine: Color(hex: "#555555"),
        thickGridLine: Color(hex: "#000000"),
        selectedCell: Color(hex: "#FFD600"),
        relatedCell: Color(hex: "#EEEEEE"),
        sameNumberCell: Color(hex: "#DDDDDD"),
        selectedEmptyCell: Color(hex: "#FFFDE7"),
        errorCell: Color(hex: "#FFEBEE"),
        pencilMarkText: Color(hex: "#555555"),
        numberPadButton: Color(hex: "#FFFFFF"),
        numberPadText: Color(hex: "#000000"),
        cardBackground: Color(hex: "#FFFFFF")
    )

    /// Yellow Paper — warm cream tones, eye-friendly. 50 coins.
    static let yellowPaper = BoardTheme(
        name: .yellowPaper,
        boardBackground: Color(hex: "#FFF8E1"),
        cellBackground: Color(hex: "#FFFDE7"),
        cellText: Color(hex: "#5D4037"),
        givenText: Color(hex: "#3E2723"),
        gridLine: Color(hex: "#D7B974"),
        thickGridLine: Color(hex: "#8D6E63"),
        selectedCell: Color(hex: "#F9A825"),
        relatedCell: Color(hex: "#FFF9C4"),
        sameNumberCell: Color(hex: "#FFF176"),
        selectedEmptyCell: Color(hex: "#FFF9C4"),
        errorCell: Color(hex: "#FFCCBC"),
        pencilMarkText: Color(hex: "#A1887F"),
        numberPadButton: Color(hex: "#FFFDE7"),
        numberPadText: Color(hex: "#5D4037"),
        cardBackground: Color(hex: "#FFFDE7")
    )

    // MARK: Paid Themes (75 coins)

    /// Nature — deep forest greens. 75 coins.
    static let nature = BoardTheme(
        name: .nature,
        boardBackground: Color(hex: "#1B3A1B"),
        cellBackground: Color(hex: "#2E4E2E"),
        cellText: Color(hex: "#81C784"),
        givenText: Color(hex: "#C8E6C9"),
        gridLine: Color(hex: "#3A5C3A"),
        thickGridLine: Color(hex: "#4C7A4C"),
        selectedCell: Color(hex: "#43A047"),
        relatedCell: Color(hex: "#243824"),
        sameNumberCell: Color(hex: "#1E3A1E"),
        selectedEmptyCell: Color(hex: "#2E4A1E"),
        errorCell: Color(hex: "#5C1A1A"),
        pencilMarkText: Color(hex: "#66BB6A"),
        numberPadButton: Color(hex: "#2E4E2E"),
        numberPadText: Color(hex: "#81C784"),
        cardBackground: Color(hex: "#2E4E2E")
    )

    /// Cityscapes — deep navy with cyan accents. 75 coins.
    static let cityscapes = BoardTheme(
        name: .cityscapes,
        boardBackground: Color(hex: "#1A1A2E"),
        cellBackground: Color(hex: "#252545"),
        cellText: Color(hex: "#7FAADC"),
        givenText: Color(hex: "#C5CAE9"),
        gridLine: Color(hex: "#2E2E50"),
        thickGridLine: Color(hex: "#3F3F6F"),
        selectedCell: Color(hex: "#5C6BC0"),
        relatedCell: Color(hex: "#1E1E38"),
        sameNumberCell: Color(hex: "#1A1A30"),
        selectedEmptyCell: Color(hex: "#252530"),
        errorCell: Color(hex: "#5C1A1A"),
        pencilMarkText: Color(hex: "#7986CB"),
        numberPadButton: Color(hex: "#252545"),
        numberPadText: Color(hex: "#7FAADC"),
        cardBackground: Color(hex: "#252545")
    )

    // MARK: Paid Themes (100 coins)

    /// Snowy — icy blues and whites. 100 coins.
    static let snowy = BoardTheme(
        name: .snowy,
        boardBackground: Color(hex: "#E8EAF6"),
        cellBackground: Color(hex: "#F5F5FF"),
        cellText: Color(hex: "#37474F"),
        givenText: Color(hex: "#263238"),
        gridLine: Color(hex: "#BBBBDD"),
        thickGridLine: Color(hex: "#90A4AE"),
        selectedCell: Color(hex: "#42A5F5"),
        relatedCell: Color(hex: "#E3F2FD"),
        sameNumberCell: Color(hex: "#B3E5FC"),
        selectedEmptyCell: Color(hex: "#E8F5FF"),
        errorCell: Color(hex: "#FFEBEE"),
        pencilMarkText: Color(hex: "#78909C"),
        numberPadButton: Color(hex: "#F5F5FF"),
        numberPadText: Color(hex: "#37474F"),
        cardBackground: Color(hex: "#F5F5FF")
    )
}
