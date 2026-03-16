import SwiftUI

// MARK: - Board Theme Name

/// Identifiable theme names stored in persistence.
/// Backward-compat: "classic" decodes as .light, "sepia" decodes as .brownishCalm.
enum BoardThemeName: String, Codable, CaseIterable, Identifiable {
    case light
    case dark
    case cherry
    case brownishCalm
    case highContrast
    case yellowPaper
    case nature
    case cityscapes
    case snowy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:         return "Light"
        case .dark:          return "Dark"
        case .cherry:        return "Cherry"
        case .brownishCalm:  return "Brownish Calm"
        case .highContrast:  return "High Contrast"
        case .yellowPaper:   return "Yellow Paper"
        case .nature:        return "Nature"
        case .cityscapes:    return "Cityscapes"
        case .snowy:         return "Snowy"
        }
    }

    /// Free themes are always available; paid themes require Gold purchase.
    var isFree: Bool { self == .light || self == .dark }

    /// Cost in Gold. Free themes cost 0.
    var price: Int {
        switch self {
        case .light, .dark:                                  return 0
        case .cherry, .brownishCalm, .highContrast, .yellowPaper: return 50
        case .nature, .cityscapes:                           return 75
        case .snowy:                                         return 100
        }
    }

    // MARK: - Backward-Compat Decoding

    /// Maps legacy raw values ("classic" -> .light, "sepia" -> .brownishCalm).
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "classic": self = .light
        case "sepia":   self = .brownishCalm
        default:
            guard let value = BoardThemeName(rawValue: raw) else {
                self = .light   // graceful fallback for unknown future values
                return
            }
            self = value
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

// MARK: - Theme Factory

extension BoardTheme {
    /// Returns the palette for a given theme name.
    static func theme(for name: BoardThemeName) -> BoardTheme {
        switch name {
        case .light:        return .light
        case .dark:         return .dark
        case .cherry:       return .cherry
        case .brownishCalm: return .brownishCalm
        case .highContrast: return .highContrast
        case .yellowPaper:  return .yellowPaper
        case .nature:       return .nature
        case .cityscapes:   return .cityscapes
        case .snowy:        return .snowy
        }
    }
}
