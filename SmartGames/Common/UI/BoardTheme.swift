import SwiftUI

// MARK: - Board Theme Name

// MARK: - Cosmetic Rarity

/// Controls how a theme is displayed in the store and which currency can purchase it.
enum CosmeticRarity: Int {
    case common     // Gold only (≤1000 gold)
    case rare       // Gold or diamonds
    case legendary  // Diamonds only — exclusive badge shown in store
}

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
    // MARK: Legendary (diamonds only — premium exclusives)
    case aurora         // deep blues + aurora greens
    case neonCity       // dark neon synthwave palette

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
        case .aurora:        return "Aurora"
        case .neonCity:      return "Neon City"
        }
    }

    /// Free themes are always available; paid themes require Gold purchase.
    var isFree: Bool { self == .light || self == .dark }

    /// Rarity tier — determines which currency can purchase the theme.
    var rarity: CosmeticRarity {
        switch self {
        case .light, .dark:                                          return .common
        case .cherry, .brownishCalm, .highContrast, .yellowPaper:   return .common
        case .nature, .cityscapes, .snowy:                           return .rare
        case .aurora, .neonCity:                                     return .legendary
        }
    }

    /// Cost in Gold. 0 for free or legendary (diamond-only) themes.
    var price: Int {
        switch self {
        case .light, .dark:                                          return 0
        case .cherry, .brownishCalm, .highContrast, .yellowPaper:   return 500
        case .nature, .cityscapes:                                   return 750
        case .snowy:                                                 return 1000
        case .aurora, .neonCity:                                     return 0   // diamonds only
        }
    }

    /// Cost in Diamonds. nil for non-diamond themes.
    var diamondPrice: Int? {
        switch self {
        case .aurora:    return 25
        case .neonCity:  return 30
        default:         return nil
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
        // Legendary themes reuse existing palettes as placeholders until dedicated palettes are designed
        case .aurora:       return .snowy
        case .neonCity:     return .dark
        }
    }
}
