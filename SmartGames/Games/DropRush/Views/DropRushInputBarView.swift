import SwiftUI

/// Bottom row of tap buttons — one per symbol in the current level's pool.
/// Flashes red briefly when wrongFlashSymbol matches.
struct DropRushInputBarView: View {
    let symbols: [String]
    let wrongFlashSymbol: String?
    let onTap: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(symbols, id: \.self) { symbol in
                Button {
                    onTap(symbol)
                } label: {
                    Text(symbol)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundStyle(.white)
                        .background(buttonBackground(symbol))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tap \(symbol)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private func buttonBackground(_ symbol: String) -> Color {
        wrongFlashSymbol == symbol ? .red : DropRushColors.color(for: symbol)
    }
}
