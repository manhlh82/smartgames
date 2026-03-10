import SwiftUI

/// Renders the full 9x9 Sudoku grid with correct thick/thin borders.
struct SudokuBoardView: View {
    @ObservedObject var viewModel: SudokuGameViewModel

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cellSize = size / 9

            ZStack {
                cellGrid(cellSize: cellSize)
                BoardGridLinesView(size: size)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cellGrid(cellSize: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { col in
                        SudokuCellView(
                            cell: viewModel.puzzle.board[row][col],
                            highlightState: viewModel.highlightState(for: row, col: col),
                            onTap: { viewModel.selectCell(row: row, col: col) }
                        )
                        .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }
}

/// Draws Sudoku grid lines — thin between cells, thick between 3x3 boxes.
private struct BoardGridLinesView: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, _ in
            let cellSize = size / 9
            let thinColor = Color.gray.opacity(0.3)
            let thickColor = Color(UIColor.label).opacity(0.7)

            for i in 0...9 {
                let x = CGFloat(i) * cellSize
                let y = CGFloat(i) * cellSize
                let isThick = i % 3 == 0
                let lineWidth: CGFloat = isThick ? 2 : 0.5
                let color = isThick ? thickColor : thinColor

                var vPath = Path()
                vPath.move(to: CGPoint(x: x, y: 0))
                vPath.addLine(to: CGPoint(x: x, y: size))
                context.stroke(vPath, with: .color(color), lineWidth: lineWidth)

                var hPath = Path()
                hPath.move(to: CGPoint(x: 0, y: y))
                hPath.addLine(to: CGPoint(x: size, y: y))
                context.stroke(hPath, with: .color(color), lineWidth: lineWidth)
            }
        }
    }
}
