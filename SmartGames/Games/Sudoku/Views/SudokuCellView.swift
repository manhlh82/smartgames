import SwiftUI

/// Renders a single Sudoku cell with its value, pencil marks, and highlight state.
struct SudokuCellView: View {
    let cell: SudokuCell
    let highlightState: CellHighlightState
    let onTap: () -> Void

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
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(cell.isGiven ? "Given clue, cannot be changed" : "")
    }

    private var backgroundColor: Color {
        switch highlightState {
        case .normal:        return Color.white
        case .selected:      return Color.sudokuSelected
        case .selectedEmpty: return Color.sudokuSelectedEmpty
        case .related:       return Color.sudokuRelated
        case .sameNumber:    return Color.sudokuSameNumber
        case .error:         return Color.sudokuError
        }
    }

    private var textColor: Color {
        switch highlightState {
        case .selected: return .white
        case .error:    return .red
        default:        return cell.isGiven ? .appTextPrimary : Color.appAccent
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
                    .foregroundColor(.gray)
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
