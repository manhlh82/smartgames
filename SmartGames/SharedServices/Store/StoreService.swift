import Foundation
import StoreKit

/// Manages In-App Purchases via StoreKit 2.
/// Handles product loading, purchase flow, restore, and entitlement tracking.
@MainActor
final class StoreService: ObservableObject {

    // MARK: - Product IDs

    static let removeAdsID      = "com.smartgames.removeads"
    static let hintPackID       = "com.smartgames.hintpack"
    // Diamond IAPs
    static let starterPackID    = "com.smartgames.starterpack"     // 50 diamonds + aurora theme, one-time
    static let diamondPack50ID  = "com.smartgames.diamonds.50"    // 50 diamonds
    static let diamondPack100ID = "com.smartgames.diamonds.100"   // 100 diamonds (best value)
    static let skipAds24hID     = "com.smartgames.skipads.24h"    // $0.99 consumable, 24h ad suppression
    static let piggyBankUnlockID = "com.smartgames.piggybank"     // unlock accumulated diamonds

    // MARK: - Published State

    @Published var products: [Product] = []
    @Published var hasRemovedAds: Bool = false
    @Published var pendingHintGrant: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var purchaseError: String? = nil
    /// Expiry date for the 24h skip-ads pass. nil = not active.
    @Published private(set) var skipAdsExpiry: Date? = nil
    /// Returns true while a skip-ads pass is active.
    var isSkipAdsActive: Bool { skipAdsExpiry.map { $0 > Date() } ?? false }

    // MARK: - Private

    private var transactionListenerTask: Task<Void, Error>?

    // MARK: - Init / Deinit

    init() {
        // Transaction listener started from SmartGamesApp to persist across view lifecycle
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        do {
            let ids: [String] = [
                StoreService.removeAdsID, StoreService.hintPackID,
                StoreService.starterPackID, StoreService.diamondPack50ID,
                StoreService.diamondPack100ID, StoreService.skipAds24hID,
                StoreService.piggyBankUnlockID
            ]
            let fetched = try await Product.products(for: ids)
            // Sort: removeAds first, then by price ascending
            products = fetched.sorted { a, b in
                if a.id == StoreService.removeAdsID { return true }
                if b.id == StoreService.removeAdsID { return false }
                return (a.price as Decimal) < (b.price as Decimal)
            }
        } catch {
            #if DEBUG
            print("[StoreService] loadProducts error: \(error)")
            #endif
        }
    }

    // MARK: - Purchase

    /// Initiates a purchase. Returns true if transaction verified and entitlements updated.
    func purchase(_ product: Product) async throws -> Bool {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateEntitlements()
            if product.id == StoreService.hintPackID {
                pendingHintGrant = true
            }
            if product.id == StoreService.skipAds24hID {
                skipAdsExpiry = Date().addingTimeInterval(86400)
            }
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            // Transaction awaiting approval (e.g. Ask to Buy)
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
            await updateEntitlements()
        } catch {
            purchaseError = "Restore failed. Please try again."
            #if DEBUG
            print("[StoreService] restorePurchases error: \(error)")
            #endif
        }
    }

    // MARK: - Transaction Listener

    /// Starts background transaction listener — call once from SmartGamesApp.
    func listenForTransactions() -> Task<Void, Error> {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                await self.handleTransactionUpdate(result)
            }
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            await updateEntitlements()
            if transaction.productID == StoreService.hintPackID {
                pendingHintGrant = true
            }
            await transaction.finish()
        } catch {
            #if DEBUG
            print("[StoreService] transaction listener error: \(error)")
            #endif
        }
    }

    // MARK: - Entitlement Check

    func updateEntitlements() async {
        var adsRemoved = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == StoreService.removeAdsID {
                adsRemoved = true
            }
        }
        hasRemovedAds = adsRemoved
    }

    // MARK: - Helpers

    /// Unwraps a VerificationResult, throwing if unverified.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    /// Convenience: find a product by ID from loaded products.
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }
}

// MARK: - StoreError

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed. Please contact support."
        }
    }
}
