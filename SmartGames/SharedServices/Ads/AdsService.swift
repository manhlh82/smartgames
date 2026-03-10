import Foundation

/// Ads service stub — always grants rewards in dev. Full implementation in PR-08.
final class AdsService: ObservableObject {
    @Published var isRewardedAdReady: Bool = true

    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        // Stub: always grant reward in development
        completion(true)
    }

    func showInterstitialIfReady() {
        // Stub
    }
}
