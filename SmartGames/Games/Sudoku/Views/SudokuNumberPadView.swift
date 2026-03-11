import SwiftUI

/// 1–9 number input pad for Sudoku — dims numbers whose digit is fully placed.
struct SudokuNumberPadView: View {
    @EnvironmentObject private var themeService: ThemeService

    let onNumberTap: (Int) -> Void
    let completedNumbers: Set<Int>

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...9, id: \.self) { n in
                Button { onNumberTap(n) } label: {
                    let isCompleted = completedNumbers.contains(n)
                    Text("\(n)")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(isCompleted
                                         ? themeService.current.numberPadText.opacity(0.3)
                                         : themeService.current.numberPadText)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(themeService.current.numberPadButton)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .disabled(completedNumbers.contains(n))
                .accessibilityLabel("\(n)")
            }
        }
        .padding(.horizontal, 8)
    }
}
