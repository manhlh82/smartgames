import SwiftUI
import StoreKit

/// Paywall sheet showing Remove Ads and Hint Pack products.
/// Presented from SettingsView or game toolbar.
struct PaywallView: View {
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    headerSection
                    productList
                    restoreButton
                    Spacer()
                }
                .padding(AppTheme.standardPadding)

                if store.isPurchasing {
                    purchasingOverlay
                }
            }
            .navigationTitle("Unlock Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.appTextSecondary)
                }
            }
            .alert("Purchase Error", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) { store.purchaseError = nil }
            } message: {
                Text(store.purchaseError ?? "")
            }
            .task { await store.loadProducts() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundColor(.appAccent)
            Text("Enhance Your Experience")
                .font(.appTitle)
                .foregroundColor(.appTextPrimary)
            Text("One-time purchases, no subscription.")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Product List

    private var productList: some View {
        VStack(spacing: 16) {
            if store.products.isEmpty {
                ProgressView("Loading products…")
                    .frame(maxWidth: .infinity)
                    .padding(32)
            } else {
                ForEach(store.products, id: \.id) { product in
                    PaywallProductRow(product: product)
                }
            }
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await store.restorePurchases() }
        }
        .font(.appBody)
        .foregroundColor(.appTextSecondary)
        .padding(.top, 4)
    }

    // MARK: - Purchasing Overlay

    private var purchasingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Processing…")
                        .font(.appBody)
                        .foregroundColor(.white)
                }
            )
    }

    // MARK: - Helpers

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { store.purchaseError != nil },
            set: { if !$0 { store.purchaseError = nil } }
        )
    }
}

// MARK: - PaywallProductRow

/// Single product row inside PaywallView.
private struct PaywallProductRow: View {
    @EnvironmentObject private var store: StoreService
    let product: Product

    var body: some View {
        HStack(spacing: 16) {
            productIcon
            productInfo
            Spacer()
            purchaseButton
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: .black.opacity(0.07), radius: AppTheme.cardShadowRadius, x: 0, y: 2)
    }

    private var productIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 28))
            .foregroundColor(iconColor)
            .frame(width: 44, height: 44)
            .background(iconColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.displayName)
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
            Text(product.description)
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
                .lineLimit(2)
        }
    }

    private var purchaseButton: some View {
        Group {
            if isOwned {
                Label("Owned", systemImage: "checkmark.circle.fill")
                    .font(.appCaption)
                    .foregroundColor(.green)
            } else {
                Button(product.displayPrice) {
                    Task {
                        do {
                            _ = try await store.purchase(product)
                        } catch {
                            store.purchaseError = error.localizedDescription
                        }
                    }
                }
                .font(.appHeadline)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.appAccent)
                .clipShape(Capsule())
                .disabled(store.isPurchasing)
            }
        }
    }

    private var isOwned: Bool {
        product.id == StoreService.removeAdsID && store.hasRemovedAds
    }

    private var iconName: String {
        product.id == StoreService.removeAdsID ? "nosign" : "lightbulb.fill"
    }

    private var iconColor: Color {
        product.id == StoreService.removeAdsID ? .red : .yellow
    }
}
