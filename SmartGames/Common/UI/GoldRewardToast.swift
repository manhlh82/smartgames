import SwiftUI

/// Animated "+X Gold" toast shown on win screens.
/// Scales in, holds briefly, then fades out automatically.
struct GoldRewardToast: View {
    let amount: Int

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.yellow)
            Text("+\(amount) Gold")
                .font(.appHeadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.72))
        .clipShape(Capsule())
        .scaleEffect(isVisible ? 1.0 : 0.6)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear { animateIn() }
        .accessibilityLabel("+\(amount) Gold earned")
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            isVisible = true
        }
        // Auto-dismiss after 2.2s
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            withAnimation(.easeOut(duration: 0.35)) {
                isVisible = false
            }
        }
    }
}
