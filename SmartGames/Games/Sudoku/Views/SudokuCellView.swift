import SwiftUI

/// Renders a single Sudoku cell with its value, pencil marks, and highlight state.
struct SudokuCellView: View {
    @EnvironmentObject private var themeService: ThemeService

    let cell: SudokuCell
    let highlightState: CellHighlightState
    let lastCompletedNumber: Int?
    let onTap: () -> Void

    @State private var isPulsing: Bool = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                backgroundColor
                if let value = cell.value {
                    Text("\(value)")
                        .font(.system(size: 22, weight: cell.isGiven ? .semibold : .regular))
                        .foregroundColor(textColor)
                } else if !cell.pencilMarks.isEmpty {
                    pencilMarksView
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())  // ensures full cell area is tappable, even when empty
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(isPulsing ? 1.12 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPulsing)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(cell.isGiven ? "Given clue, cannot be changed" : "")
        .onChange(of: lastCompletedNumber) { completed in
            guard let completed, cell.value == completed else { return }
            isPulsing = true
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                isPulsing = false
            }
        }
    }

    private var theme: BoardTheme { themeService.current }

    /// Maps CellHighlightState to the theme's cell background color.
    private var backgroundColor: Color {
        switch highlightState {
        case .normal:        return theme.cellBackground
        case .selected:      return theme.selectedCell
        case .selectedEmpty: return theme.selectedEmptyCell
        case .related:       return theme.relatedCell
        case .sameNumber:    return theme.sameNumberCell
        case .error:         return theme.errorCell
        }
    }

    /// Maps highlight state and cell type to the theme's text color.
    private var textColor: Color {
        switch highlightState {
        case .selected: return .white
        case .error:    return .red
        default:        return cell.isGiven ? theme.givenText : theme.cellText
        }
    }

    private var pencilMarksView: some View {
        let sorted = Array(cell.pencilMarks).sorted()
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3),
            spacing: 0
        ) {
            ForEach(1...9, id: \.self) { n in
                Text(sorted.contains(n) ? "\(n)" : " ")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(theme.pencilMarkText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(2)
    }

    private var accessibilityLabel: String {
        let pos = "Row \(cell.row + 1), Column \(cell.col + 1)"
        if let value = cell.value {
            return "\(pos), \(value)\(cell.isGiven ? ", given clue" : "")"
        }
        if !cell.pencilMarks.isEmpty {
            return "\(pos), notes: \(cell.pencilMarks.sorted().map(String.init).joined(separator: ", "))"
        }
        return "\(pos), empty"
    }
}
