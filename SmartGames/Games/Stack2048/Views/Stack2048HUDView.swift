import SwiftUI

/// Top HUD: Gold balance (left) | current score (center) | high score + pause (right).
struct Stack2048HUDView: View {
    let score: Int
    let highScore: Int
    let phase: Stack2048Phase
    let onPause: () -> Void
    let onResume: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // Gold balance — reuse shared component
            GoldBalanceView()
                .frame(minWidth: 80, alignment: .leading)

            Spacer()

            // Current score (center, gold when > 0)
            Text("\(score)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(score > 0 ? Color(red: 0.91, green: 0.66, blue: 0.09) : .white.opacity(0.7))
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: score)

            Spacer()

            // High score + pause
            HStack(spacing: 10) {
                Label("\(highScore)", systemImage: "crown.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.91, green: 0.66, blue: 0.09))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())

                let isInteractive = phase == .playing || phase == .paused
                Button {
                    phase == .paused ? onResume() : onPause()
                } label: {
                    Image(systemName: phase == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isInteractive ? .white : .white.opacity(0.4))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(!isInteractive)
            }
            .frame(minWidth: 80, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
