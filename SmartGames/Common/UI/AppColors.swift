import SwiftUI

/// App-wide color palette.
extension Color {
    static let appAccent = Color(hex: "#007AFF")
    static let appBackground = Color(UIColor.systemGroupedBackground)
    static let appCard = Color.white
    static let appTextPrimary = Color(hex: "#1C1C1E")
    static let appTextSecondary = Color(hex: "#8E8E93")

    // Sudoku cell highlight colors
    static let sudokuSelected = Color(hex: "#1565C0")
    static let sudokuRelated = Color(hex: "#E3F2FD")
    static let sudokuSameNumber = Color(hex: "#B2EBF2")
    static let sudokuSelectedEmpty = Color(hex: "#FFF9C4")
    static let sudokuError = Color(hex: "#FFEBEE")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
