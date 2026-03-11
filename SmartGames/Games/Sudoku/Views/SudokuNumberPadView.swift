import SwiftUI

/// 1–9 number input pad for Sudoku — dims completed numbers, highlights selected, shows remaining count.
struct SudokuNumberPadView: View {
    @EnvironmentObject private var themeService: ThemeService

    let onNumberTap: (Int) -> Void
    let completedNumbers: Set<Int>
    var selectedNumber: Int? = nil
    var remainingCounts: [Int: Int] = [:]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...9, id: \.self) { n in
                Button { onNumberTap(n) } label: {
                    numberButtonLabel(n)
                }
                .buttonStyle(.plain)
                .disabled(completedNumbers.contains(n))
                .accessibilityLabel("\(n)")
            }
        }
        .padding(.horizontal, 8)
    }

    private func numberButtonLabel(_ n: Int) -> some View {
        let isCompleted = completedNumbers.contains(n)
        let isSelected = selectedNumber == n
        let remaining = remainingCounts[n] ?? 0

        return ZStack(alignment: .bottom) {
            VStack(spacing: 2) {
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
                    .overlay(
                        Circle()
                            .stroke(Color.appAccent, lineWidth: 2)
                            .opacity(isSelected ? 1 : 0)
                    )

                if !isCompleted && remaining > 0 {
                    Text("×\(remaining)")
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
    }
}
