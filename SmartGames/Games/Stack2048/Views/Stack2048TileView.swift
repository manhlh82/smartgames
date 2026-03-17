import SwiftUI

/// Single tile — colored rounded rectangle with value label.
/// Pulses on merge via `isMergedThisTurn` flag.
struct Stack2048TileView: View {
    let tile: Stack2048Tile
    let size: CGFloat
    var isHammerTarget: Bool = false

    @State private var pulsed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(Stack2048Colors.background(for: tile.value))

            // Hammer mode highlight
            if isHammerTarget {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .strokeBorder(Color.red, lineWidth: 2)
            }

            Text(formattedValue)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Stack2048Colors.text(for: tile.value))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(width: size, height: size)
        .scaleEffect(pulsed ? 1.18 : 1.0)
        .onChange(of: tile.isMergedThisTurn) { merged in
            guard merged else { return }
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                pulsed = true
            }
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4).delay(0.15)) {
                pulsed = false
            }
        }
    }

    private var formattedValue: String {
        tile.value >= 1000 ? "\(tile.value / 1000)K" : "\(tile.value)"
    }

    private var fontSize: CGFloat {
        switch tile.value {
        case ..<100:   return size * 0.42
        case ..<1000:  return size * 0.36
        default:       return size * 0.30
        }
    }
}
