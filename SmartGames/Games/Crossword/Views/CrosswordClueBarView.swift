import SwiftUI

struct CrosswordClueBarView: View {
    @ObservedObject var viewModel: CrosswordGameViewModel

    var body: some View {
        Button {
            viewModel.selectedDirection = viewModel.selectedDirection == .across ? .down : .across
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.selectedDirection == .across ? "arrow.right" : "arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appAccent)
                if let clue = viewModel.activeClue {
                    Text("\(clue.number)\(viewModel.selectedDirection == .across ? "A" : "D"): \(clue.text)")
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(1)
                } else {
                    Text("Tap a cell to see its clue")
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                Image(systemName: "list.bullet")
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, AppTheme.standardPadding)
            .padding(.vertical, 10)
            .background(Color.appCard)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle direction. Current clue: \(viewModel.activeClue?.text ?? "none")")
    }
}
