import SwiftUI

/// Renders the full 9x9 Sudoku grid with correct thick/thin borders.
struct SudokuBoardView: View {
    @EnvironmentObject private var themeService: ThemeService
    @ObservedObject var viewModel: SudokuGameViewModel

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cellSize = size / 9

            ZStack {
                themeService.current.boardBackground
                cellGrid(cellSize: cellSize)
                BoardGridLinesView(
                    size: size,
                    thinColor: themeService.current.gridLine,
                    thickColor: themeService.current.thickGridLine
                )
                .allowsHitTesting(false)
                // Subgrid celebration overlay — rendered above grid lines, non-blocking
                if let idx = viewModel.celebratingSubgrid {
                    SubgridCelebrationOverlay(subgridIndex: idx, cellSize: cellSize)
                        .allowsHitTesting(false)
                }
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
                            lastCompletedNumber: viewModel.lastCompletedNumber,
                            onTap: { viewModel.selectCell(row: row, col: col) }
                        )
                        .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }
}

/// Short celebration animation overlay for a single 3×3 subgrid.
/// Renders a soft gold tint with a spring scale pulse over the target box.
private struct SubgridCelebrationOverlay: View {
    let subgridIndex: Int
    let cellSize: CGFloat

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.0

    private var boxRow: Int { subgridIndex / 3 }
    private var boxCol: Int { subgridIndex % 3 }

    var body: some View {
        let boxSize = cellSize * 3
        let xOffset = CGFloat(boxCol) * boxSize + boxSize / 2
        let yOffset = CGFloat(boxRow) * boxSize + boxSize / 2

        RoundedRectangle(cornerRadius: 4)
            .fill(Color.yellow.opacity(0.28))
            .frame(width: boxSize - 2, height: boxSize - 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(x: xOffset, y: yOffset)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.04
                    opacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                    scale = 1.0
                    opacity = 0.0
                }
            }
    }
}

/// Draws Sudoku grid lines — thin between cells, thick between 3x3 boxes.
/// Colors are passed in from the active BoardTheme.
private struct BoardGridLinesView: View {
    let size: CGFloat
    let thinColor: Color
    let thickColor: Color

    var body: some View {
        Canvas { context, _ in
            let cellSize = size / 9

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
