import SwiftUI

/// App-wide font scale.
extension Font {
    static let appTitle = Font.system(size: 28, weight: .bold)
    static let appHeadline = Font.system(size: 18, weight: .semibold)
    static let appBody = Font.system(size: 16, weight: .regular)
    static let appCaption = Font.system(size: 13, weight: .regular)
    static let appMono = Font.system(size: 16, weight: .regular, design: .monospaced)
}
