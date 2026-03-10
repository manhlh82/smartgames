import SwiftUI

/// Game tool buttons: Undo, Eraser, Pencil, Hint.
struct SudokuToolbarView: View {
    @ObservedObject var viewModel: SudokuGameViewModel

    var body: some View {
        HStack(spacing: 0) {
            toolButton(icon: "arrow.uturn.backward", label: "Undo",
                       isDisabled: !viewModel.isUndoAvailable) {
                viewModel.undo()
            }
            toolButton(icon: "eraser", label: "Eraser") {
                viewModel.eraseSelected()
            }
            toolButton(icon: "pencil", label: "Pencil",
                       isActive: viewModel.isPencilMode) {
                viewModel.togglePencilMode()
            }
            hintButton
        }
    }

    private func toolButton(
        icon: String,
        label: String,
        isActive: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(buttonIconColor(isActive: isActive, isDisabled: isDisabled))
                Text(label)
                    .font(.appCaption)
                    .foregroundColor(isDisabled ? .gray.opacity(0.4) : .appTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(label)
    }

    private func buttonIconColor(isActive: Bool, isDisabled: Bool) -> Color {
        if isDisabled { return .gray.opacity(0.4) }
        if isActive { return Color.appAccent }
        return .appTextPrimary
    }

    private var hintButton: some View {
        let hintLabel = viewModel.hintsRemaining == 0
            ? "Hint, watch ad for hints"
            : "Hint, \(viewModel.hintsRemaining) remaining"

        return Button { viewModel.useHint() } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 22))
                        .foregroundColor(.appTextPrimary)
                    if viewModel.hintsRemaining == 0 {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.appAccent)
                            .offset(x: 6, y: -4)
                    }
                }
                Text("Hint")
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(hintLabel)
    }
}
