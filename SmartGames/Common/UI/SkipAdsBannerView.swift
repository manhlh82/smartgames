import SwiftUI

/// Non-intrusive banner shown after N ad-watches in a day.
/// Offers "Remove Ads" IAP or "Skip Ads 24h" pass.
struct SkipAdsBannerView: View {
    let onRemoveAds: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "nosign")
                .font(.system(size: 20))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Tired of ads?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Remove ads or get a 24h pass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onRemoveAds) {
                Text("View")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 8)
        .padding(.horizontal, 16)
    }
}
