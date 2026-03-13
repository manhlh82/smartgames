import SwiftUI

/// Compact Gold balance badge — shows a coin icon and current balance.
/// Place in picker headers, settings rows, or win screens.
struct GoldBalanceView: View {
    @EnvironmentObject var gold: GoldService

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.yellow)
            Text("\(gold.balance)")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
        }
        .accessibilityLabel("\(gold.balance) Gold")
    }
}
