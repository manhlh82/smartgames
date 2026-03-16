import SwiftUI

/// Top HUD bar: score (left), lives as hearts (center), combo badge, timer, pause (right).
struct DropRushHUDView: View {
    let state: EngineState
    let phase: DropRushPhase
    let onPause: () -> Void
    let onResume: () -> Void

    /// Drives scale pulse when combo hits a milestone.
    @State private var comboPulse: Bool = false

    // MARK: - Helpers

    private var elapsedFormatted: String {
        let total = Int(state.elapsedTime)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack {
            // Score
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("\(state.score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            .frame(minWidth: 64, alignment: .leading)

            Spacer()

            // Center stack: lives + combo badge
            VStack(spacing: 4) {
                // Lives
                HStack(spacing: 4) {
                    ForEach(0..<max(3, state.livesRemaining), id: \.self) { i in
                        Image(systemName: i < state.livesRemaining ? "heart.fill" : "heart")
                            .foregroundStyle(i < state.livesRemaining ? Color.red : Color.secondary.opacity(0.4))
                            .font(.system(size: 18))
                    }
                }

                // Combo badge — visible at 3+ consecutive hits
                if state.comboCount >= 3 {
                    Text("×\(String(format: "%.1g", state.comboMultiplier)) COMBO")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                        .scaleEffect(comboPulse ? 1.3 : 1.0)
                }
            }
            .animation(.spring, value: state.comboCount)
            .onChange(of: state.comboCount) { newCount in
                // Pulse on milestone hits: 5, 10, 15, 20…
                if newCount > 0 && newCount % 5 == 0 {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                        comboPulse = true
                    }
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.4).delay(0.15)) {
                        comboPulse = false
                    }
                }
            }

            Spacer()

            // Timer + speed badge + pause
            HStack(spacing: 10) {
                // Elapsed timer
                VStack(alignment: .trailing, spacing: 2) {
                    Text("TIME")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(elapsedFormatted)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }

                if state.currentSpeedMultiplier > 1.0 {
                    Text(String(format: "×%.1f", state.currentSpeedMultiplier))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }

                let isInteractive = phase == .playing || phase == .paused
                Button {
                    phase == .paused ? onResume() : onPause()
                } label: {
                    Image(systemName: phase == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(isInteractive ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!isInteractive)
                .accessibilityLabel(phase == .paused ? "Resume" : "Pause")
            }
            .frame(minWidth: 64, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
