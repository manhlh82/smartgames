import Foundation
import StoreKit

/// Manages In-App Purchases via StoreKit 2.
/// Handles product loading, purchase flow, restore, and entitlement tracking.
@MainActor
final class StoreService: ObservableObject {

    // MARK: - Product IDs

    static let removeAdsID = "com.smartgames.removeads"
    static let hintPackID  = "com.smartgames.hintpack"

    // MARK: - Published State

    @Published var products: [Product] = []
    @Published var hasRemovedAds: Bool = false
    @Published var pendingHintGrant: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var purchaseError: String? = nil

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
            let ids: [String] = [StoreService.removeAdsID, StoreService.hintPackID]
            let fetched = try await Product.products(for: ids)
            // Sort: removeAds first
            products = fetched.sorted { a, _ in a.id == StoreService.removeAdsID }
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
