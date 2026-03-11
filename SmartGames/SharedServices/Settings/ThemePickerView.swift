import SwiftUI

// MARK: - ThemePickerView

/// Horizontal row of theme swatches for the Settings screen.
/// Each swatch shows a mini 3x3 board preview using that theme's colors.
struct ThemePickerView: View {
    @EnvironmentObject var themeService: ThemeService

    var body: some View {
        HStack(spacing: 16) {
            ForEach(BoardThemeName.allCases) { name in
                ThemeSwatchView(
                    theme: BoardTheme.theme(for: name),
                    isSelected: themeService.themeName == name
                )
                .onTapGesture { themeService.setTheme(name) }
                .accessibilityLabel("\(name.displayName) theme")
                .accessibilityAddTraits(themeService.themeName == name ? .isSelected : [])
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - ThemeSwatchView

/// Mini board preview swatch with checkmark when selected.
private struct ThemeSwatchView: View {
    let theme: BoardTheme
    let isSelected: Bool

    private let swatchSize: CGFloat = 72
    private let cellCount = 3

    var body: some View {
        ZStack(alignment: .topTrailing) {
            miniBoard
                .frame(width: swatchSize, height: swatchSize)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.appAccent : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2.5 : 1)
                )

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.appAccent)
                    .background(Circle().fill(Color.white).padding(2))
                    .offset(x: 6, y: -6)
            }
        }
        .overlay(
            Text(theme.name.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(theme.givenText)
                .padding(.bottom, 4),
            alignment: .bottom
        )
    }

    /// 3x3 grid of colored cells mimicking the board layout.
    private var miniBoard: some View {
        VStack(spacing: 1) {
            ForEach(0..<cellCount, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<cellCount, id: \.self) { col in
                        // Highlight centre cell to show selected-cell color
                        let isCenter = row == 1 && col == 1
                        Rectangle()
                            .fill(isCenter ? theme.selectedCell : theme.cellBackground)
                    }
                }
            }
        }
        .background(theme.thickGridLine)
        .padding(2)
        .background(theme.boardBackground)
    }
}
