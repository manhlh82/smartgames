import SwiftUI

/// Compact dual-currency badge — diamonds (bright cyan) left, gold (subdued) right.
/// Use in game HUDs, overlays, and store headers.
struct CurrencyBarView: View {
    @EnvironmentObject var gold: GoldService
    @EnvironmentObject var diamonds: DiamondService

    var body: some View {
        HStack(spacing: 10) {
            // Diamond — primary / bright
            HStack(spacing: 3) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.cyan)
                Text("\(diamonds.balance)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.cyan)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .accessibilityLabel("\(diamonds.balance) Diamonds")

            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 1, height: 14)

            // Gold — subdued
            HStack(spacing: 3) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.yellow.opacity(0.75))
                Text("\(gold.balance)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.6))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .accessibilityLabel("\(gold.balance) Gold")
        }
    }
}
