import SwiftUI

/// Compact Gold balance badge — shows a coin icon and current balance.
/// Place in picker headers, settings rows, or win screens.
struct GoldBalanceView: View {
    @EnvironmentObject var gold: GoldService

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.yellow)
            Text("\(gold.balance)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityLabel("\(gold.balance) Gold")
    }
}
