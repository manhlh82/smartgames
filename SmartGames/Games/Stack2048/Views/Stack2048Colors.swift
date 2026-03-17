import SwiftUI

/// Tile color scheme matching the standard 2048 visual language.
enum Stack2048Colors {

    static func background(for value: Int) -> Color {
        switch value {
        case 2:    return Color(red: 0.36, green: 0.64, blue: 0.81)   // sky blue
        case 4:    return Color(red: 0.24, green: 0.70, blue: 0.66)   // teal
        case 8:    return Color(red: 0.96, green: 0.47, blue: 0.23)   // orange
        case 16:   return Color(red: 0.91, green: 0.66, blue: 0.09)   // gold
        case 32:   return Color(red: 0.80, green: 0.52, blue: 0.25)   // brown
        case 64:   return Color(red: 0.88, green: 0.36, blue: 0.23)   // red-orange
        case 128:  return Color(red: 0.16, green: 0.67, blue: 0.54)   // teal-green
        case 256:  return Color(red: 0.94, green: 0.75, blue: 0.25)   // yellow
        case 512:  return Color(red: 0.30, green: 0.69, blue: 0.31)   // green
        case 1024: return Color(red: 0.61, green: 0.35, blue: 0.71)   // purple
        case 2048: return Color(red: 0.96, green: 0.65, blue: 0.14)   // bright gold
        default:   return Color(red: 0.36, green: 0.25, blue: 0.82)   // deep purple (4096+)
        }
    }

    static func text(for value: Int) -> Color {
        // Dark background tiles get white text; lighter ones slightly dimmer
        return .white
    }
}
