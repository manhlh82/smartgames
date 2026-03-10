import SwiftUI

/// 1–9 number input pad for Sudoku — dims numbers whose digit is fully placed.
struct SudokuNumberPadView: View {
    let onNumberTap: (Int) -> Void
    let completedNumbers: Set<Int>

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...9, id: \.self) { n in
                Button { onNumberTap(n) } label: {
                    Text("\(n)")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(completedNumbers.contains(n)
                                         ? .gray.opacity(0.4)
                                         : Color.appAccent)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(Color.white)
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
