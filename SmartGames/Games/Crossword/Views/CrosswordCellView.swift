import SwiftUI

enum CrosswordCheckFeedback { case none, correct, incorrect }

struct CrosswordCellView: View {
    let cellState: CrosswordCellState
    let isSelected: Bool
    let isInSelectedWord: Bool
    let checkFeedback: CrosswordCheckFeedback

    var body: some View {
        ZStack {
            cellBackground
            if !cellState.isBlack {
                if let num = cellState.clueNumber {
                    Text("\(num)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, 2).padding(.top, 1)
                }
                if let entry = cellState.userEntry {
                    Text(String(entry))
                        .font(.system(size: 18, weight: cellState.isRevealed ? .light : .regular))
                        .foregroundColor(cellState.isRevealed ? .gray : .primary)
                        .italic(cellState.isRevealed)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .border(Color.gray.opacity(0.4), width: 0.5)
    }

    private var cellBackground: Color {
        if cellState.isBlack { return Color(.systemGray2) }
        switch checkFeedback {
        case .correct:   return Color.green.opacity(0.3)
        case .incorrect: return Color.red.opacity(0.3)
        case .none:
            if isSelected { return Color.blue.opacity(0.35) }
            if isInSelectedWord { return Color.blue.opacity(0.12) }
            return Color(.systemBackground)
        }
    }
}
