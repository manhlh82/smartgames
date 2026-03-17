import SwiftUI

struct CrosswordGridView: View {
    @ObservedObject var viewModel: CrosswordGameViewModel

    var body: some View {
        GeometryReader { geo in
            let size = viewModel.puzzle.size
            let cellSize = geo.size.width / CGFloat(size)
            VStack(spacing: 0) {
                ForEach(0..<size, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<size, id: \.self) { col in
                            let cell = viewModel.boardState.cells[row][col]
                            let isSelected = viewModel.selectedRow == row
                                && viewModel.selectedCol == col
                            let isInWord = viewModel.isInSelectedWord(row: row, col: col)
                            let feedback = feedbackFor(row: row, col: col)
                            CrosswordCellView(
                                cellState: cell,
                                isSelected: isSelected,
                                isInSelectedWord: isInWord,
                                checkFeedback: feedback
                            )
                            .frame(width: cellSize, height: cellSize)
                            .onTapGesture { viewModel.selectCell(row: row, col: col) }
                        }
                    }
                }
            }
            .border(Color.gray, width: 1)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func feedbackFor(row: Int, col: Int) -> CrosswordCheckFeedback {
        guard let fb = viewModel.checkFeedbackCell,
              fb.row == row, fb.col == col else { return .none }
        return fb.correct ? .correct : .incorrect
    }
}
