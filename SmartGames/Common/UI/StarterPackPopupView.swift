import SwiftUI
import StoreKit

/// First-session starter pack offer popup.
/// Shows 50 diamonds + Aurora exclusive theme for a one-time IAP price.
/// Triggered on first game loss or after 5 minutes in session.
struct StarterPackPopupView: View {
    @EnvironmentObject var starterPack: StarterPackService
    @EnvironmentObject var diamonds: DiamondService
    @EnvironmentObject var themeService: ThemeService
    @EnvironmentObject var store: StoreService

    @State private var isPurchasing = false

    private var starterProduct: Product? {
        store.products.first { $0.id == StoreService.starterPackID }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        Text("Starter Pack")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    Text("Limited one-time offer")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                // Contents
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "diamond.fill")
                            .foregroundStyle(.cyan)
                        Text("50 Diamonds")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Text("Premium currency")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                    HStack(spacing: 10) {
                        Image(systemName: "paintpalette.fill")
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing)
                            )
                        Text("Aurora Theme")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Text("EXCLUSIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Purchase button
                Button {
                    Task { await purchase() }
                } label: {
                    if isPurchasing {
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    } else {
                        HStack {
                            Text("Get Starter Pack")
                                .font(.system(size: 17, weight: .semibold))
                            Spacer()
                            Text(starterProduct.map { $0.displayPrice } ?? "—")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 50)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .buttonStyle(.plain)
                .disabled(isPurchasing || starterProduct == nil)

                Button("No thanks") {
                    starterPack.dismissOffer()
                }
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.25), radius: 24)
            .padding(.horizontal, 28)
        }
    }

    private func purchase() async {
        guard let product = starterProduct else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let success = try await store.purchase(product)
            if success {
                starterPack.claimRewards(diamondService: diamonds, themeService: themeService)
            }
        } catch {
            // Purchase cancelled or failed — leave popup open
        }
    }
}
