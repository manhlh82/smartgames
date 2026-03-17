import SwiftUI

/// 5-column tile grid. Handles column-tap (drop) and tile-tap (hammer mode).
struct Stack2048BoardView: View {
    let gameState: Stack2048GameState
    let phase: Stack2048Phase
    let onColumnTap: (Int) -> Void
    let onTileTap: (Int, Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let totalSpacing = spacing * CGFloat(Stack2048GameState.columnCount - 1)
            let tileSize = (geo.size.width - totalSpacing) / CGFloat(Stack2048GameState.columnCount)

            HStack(spacing: spacing) {
                ForEach(0..<Stack2048GameState.columnCount, id: \.self) { col in
                    columnView(col: col, tileSize: tileSize, totalHeight: geo.size.height)
                }
            }
        }
    }

    // MARK: - Column

    @ViewBuilder
    private func columnView(col: Int, tileSize: CGFloat, totalHeight: CGFloat) -> some View {
        let tiles = gameState.columns[col]
        let isFull = tiles.count >= Stack2048GameState.maxRows

        ZStack(alignment: .top) {
            // Column background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(phase == .hammerMode ? 0.03 : 0.06))

            // Drop indicator (dashed border) — shown in playing mode on non-full columns
            if phase == .playing && !isFull {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        Color.white.opacity(0.15),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
            }

            // Tiles stacked from top
            VStack(spacing: 2) {
                ForEach(0..<Stack2048GameState.maxRows, id: \.self) { row in
                    if row < tiles.count {
                        Stack2048TileView(
                            tile: tiles[row],
                            size: tileSize,
                            isHammerTarget: phase == .hammerMode
                        )
                        .onTapGesture {
                            if phase == .hammerMode {
                                onTileTap(col, row)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.6).combined(with: .opacity),
                            removal: .scale(scale: 0.3).combined(with: .opacity)
                        ))
                    } else {
                        Color.clear
                            .frame(width: tileSize, height: tileSize)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(2)
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard phase == .playing, !isFull else { return }
            onColumnTap(col)
        }
        .animation(.easeInOut(duration: 0.15), value: tiles.count)
    }
}
