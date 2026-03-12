import SwiftUI
import UIKit

/// SwiftUI wrapper for a banner ad.
/// In production, wraps GADBannerView via UIViewRepresentable.
/// Stub: renders a placeholder view while real AdMob SDK is not yet integrated.
struct BannerAdView: UIViewRepresentable {
    @ObservedObject var coordinator: BannerAdCoordinator

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemGray6
        // Stub: show a placeholder label in debug/test mode
        #if DEBUG
        let label = UILabel()
        label.text = "Test Ad"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        #endif
        // Trigger banner load on first display
        Task { @MainActor in
            coordinator.loadBanner()
        }
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No dynamic updates needed — coordinator state drives SwiftUI layout via @Published
    }
}
