import SwiftUI

// MARK: - Board Theme Name

/// Identifiable theme names stored in persistence.
enum BoardThemeName: String, Codable, CaseIterable, Identifiable {
    case classic
    case dark
    case sepia

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .dark:    return "Dark"
        case .sepia:   return "Sepia"
        }
    }
}

// MARK: - Board Theme

/// Full color palette for Sudoku board rendering.
struct BoardTheme {
    let name: BoardThemeName
    let boardBackground: Color
    let cellBackground: Color
    let cellText: Color
    let givenText: Color
    let gridLine: Color
    let thickGridLine: Color
    let selectedCell: Color
    let relatedCell: Color
    let sameNumberCell: Color
    let selectedEmptyCell: Color
    let errorCell: Color
    let pencilMarkText: Color
    let numberPadButton: Color
    let numberPadText: Color
    let cardBackground: Color
}

// MARK: - Static Palettes

extension BoardTheme {
    /// Classic light theme — matches original app colors exactly.
    static let classic = BoardTheme(
        name: .classic,
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

    /// Dark theme — dark gray board with high-contrast text.
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

    /// Sepia theme — warm tan and brown palette for eye comfort.
    static let sepia = BoardTheme(
        name: .sepia,
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

    /// Returns the palette for a given theme name.
    static func theme(for name: BoardThemeName) -> BoardTheme {
        switch name {
        case .classic: return .classic
        case .dark:    return .dark
        case .sepia:   return .sepia
        }
    }
}
