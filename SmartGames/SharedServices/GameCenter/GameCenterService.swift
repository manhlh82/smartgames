import GameKit
import UIKit

/// Manages Game Center authentication, leaderboard score submission, and leaderboard display.
/// All methods are safe to call when unauthenticated — they silently no-op.
@MainActor
final class GameCenterService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var localPlayerName: String?

    // MARK: - Leaderboard IDs

    /// Drop Rush cumulative leaderboard IDs.
    enum DropRushLeaderboardID {
        static let cumulative = "com.smartgames.dropRush.leaderboard.cumulative"
    }

    /// Leaderboard IDs configured in App Store Connect.
    /// Sort order: ascending (lower time = better).
    enum LeaderboardID {
        static let easy   = "com.smartgames.sudoku.leaderboard.easy"
        static let medium = "com.smartgames.sudoku.leaderboard.medium"
        static let hard   = "com.smartgames.sudoku.leaderboard.hard"
        static let expert = "com.smartgames.sudoku.leaderboard.expert"

        static func id(for difficulty: SudokuDifficulty) -> String {
            "com.smartgames.sudoku.leaderboard.\(difficulty.rawValue)"
        }
    }

    // MARK: - Authentication

    /// Call once on app launch. Silent if player already authenticated.
    /// Presents sign-in UI only when needed (first launch / signed out).
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let vc = viewController {
                    // Present Game Center sign-in UI
                    self.presentViewController(vc)
                }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self.localPlayerName = GKLocalPlayer.local.isAuthenticated
                    ? GKLocalPlayer.local.displayName
                    : nil
                if let error {
                    #if DEBUG
                    print("[GameCenter] Auth error: \(error.localizedDescription)")
                    #endif
                }
            }
        }
    }

    // MARK: - Score Submission

    /// Submits elapsed time (in seconds) to the difficulty-specific leaderboard.
    /// Fire-and-forget — does not block game flow. Silent on failure.
    func submitScore(_ seconds: Int, difficulty: SudokuDifficulty) {
        guard isAuthenticated, seconds > 0 else { return }
        let leaderboardID = LeaderboardID.id(for: difficulty)
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    seconds,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
                #if DEBUG
                print("[GameCenter] Submitted \(seconds)s for \(leaderboardID)")
                #endif
            } catch {
                #if DEBUG
                print("[GameCenter] Score submission failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Submits a score to any leaderboard by ID. Fire-and-forget.
    func submitScore(_ score: Int, leaderboardID: String) {
        guard isAuthenticated, score > 0 else { return }
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score, context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
            } catch {
                #if DEBUG
                print("[GameCenter] Score submission failed for \(leaderboardID): \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Leaderboard Display

    /// Presents the native Game Center leaderboard UI.
    /// Pass nil difficulty to show all leaderboards.
    func showLeaderboard(for difficulty: SudokuDifficulty? = nil) {
        guard isAuthenticated else { return }
        let gcVC = GKGameCenterViewController(state: .leaderboards)
        if let difficulty {
            gcVC.leaderboardIdentifier = LeaderboardID.id(for: difficulty)
        }
        gcVC.gameCenterDelegate = GameCenterDismissDelegate.shared
        presentViewController(gcVC)
    }

    /// Presents the Drop Rush cumulative score leaderboard.
    func showDropRushLeaderboard() {
        guard isAuthenticated else { return }
        let gcVC = GKGameCenterViewController(state: .leaderboards)
        gcVC.leaderboardIdentifier = DropRushLeaderboardID.cumulative
        gcVC.gameCenterDelegate = GameCenterDismissDelegate.shared
        presentViewController(gcVC)
    }

    // MARK: - Private

    private func presentViewController(_ vc: UIViewController) {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            #if DEBUG
            print("[GameCenter] No root view controller found")
            #endif
            return
        }
        // Find the topmost presented controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        topVC.present(vc, animated: true)
    }
}

// MARK: - Dismiss Delegate

/// Handles dismissal of GKGameCenterViewController.
private final class GameCenterDismissDelegate: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismissDelegate()

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
