import SwiftUI

/// Limited-time sale popup — triggered after N consecutive losses.
/// Shows a countdown timer and a discounted diamond pack CTA.
struct TimedSalePopupView: View {
    let expiresAt: Date
    let discountLabel: String
    let onShop: () -> Void
    let onDismiss: () -> Void

    @State private var timeRemaining: String = ""
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 18) {
                // Flash badge
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Text("LIMITED TIME OFFER")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.yellow.opacity(0.15))
                .clipShape(Capsule())

                Text(discountLabel)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Diamond Pack")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                // Countdown
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundStyle(.orange)
                    Text(timeRemaining)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())

                VStack(spacing: 8) {
                    Button(action: onShop) {
                        Label("Shop Now", systemImage: "diamond.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button("Maybe later", action: onDismiss)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                }
            }
            .padding(28)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 24)
            .padding(.horizontal, 28)
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func startTimer() {
        updateRemaining()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateRemaining()
            if Date() >= expiresAt {
                timer?.invalidate()
                onDismiss()
            }
        }
    }

    private func updateRemaining() {
        let remaining = max(expiresAt.timeIntervalSinceNow, 0)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        timeRemaining = String(format: "%d:%02d", minutes, seconds)
    }
}
