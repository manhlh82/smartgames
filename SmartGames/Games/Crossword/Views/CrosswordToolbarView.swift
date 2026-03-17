import SwiftUI

struct CrosswordToolbarView: View {
    @ObservedObject var viewModel: CrosswordGameViewModel

    var body: some View {
        HStack(spacing: 12) {
            toolbarButton(
                icon: "arrow.uturn.backward",
                label: "Undo",
                enabled: viewModel.isUndoAvailable,
                action: { viewModel.undo() }
            )
            toolbarButton(
                icon: "checkmark.circle",
                label: "Check\n(\(viewModel.hintsRemaining))",
                enabled: viewModel.gamePhase == .playing,
                action: { viewModel.checkLetter() }
            )
            toolbarButton(
                icon: "lightbulb",
                label: "Letter\n(\(viewModel.hintsRemaining))",
                enabled: viewModel.gamePhase == .playing,
                action: { viewModel.revealLetter() }
            )
            toolbarButton(
                icon: "lightbulb.fill",
                label: "Word\n(3+)",
                enabled: viewModel.gamePhase == .playing && viewModel.hintsRemaining >= 3,
                action: { viewModel.revealWord() }
            )
            toolbarButton(
                icon: "diamond.fill",
                label: "1 Gem",
                enabled: viewModel.gamePhase == .playing && viewModel.diamondService.balance >= 1,
                action: { viewModel.revealLetterWithDiamond() },
                tint: .cyan
            )
        }
        .padding(.horizontal, AppTheme.standardPadding)
    }

    private func toolbarButton(
        icon: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void,
        tint: Color = .appAccent
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(enabled ? tint : .gray)
            .frame(maxWidth: .infinity)
        }
        .disabled(!enabled)
        .accessibilityLabel(label.replacingOccurrences(of: "\n", with: " "))
    }
}
