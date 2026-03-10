import SwiftUI

/// Full-screen pause overlay — hides board to prevent cheating.
struct SudokuPauseOverlayView: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 12) {
                    Button("Resume", action: onResume)
                        .font(.appHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(Color.appAccent)
                        .cornerRadius(AppTheme.buttonCornerRadius)
                        .accessibilityLabel("Resume game")

                    Button("Restart", action: onRestart)
                        .font(.appBody)
                        .foregroundColor(.white.opacity(0.8))
                        .accessibilityLabel("Restart puzzle")

                    Button("Quit", action: onQuit)
                        .font(.appBody)
                        .foregroundColor(.white.opacity(0.6))
                        .accessibilityLabel("Quit to hub")
                }
            }
        }
    }
}
