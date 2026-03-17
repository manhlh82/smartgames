import SwiftUI

/// Full scrollable list of all clues grouped by Across / Down.
struct CrosswordClueListView: View {
    @ObservedObject var viewModel: CrosswordGameViewModel
    @Environment(\.dismiss) private var dismiss

    var acrossClues: [CrosswordClue] {
        viewModel.puzzle.clues
            .filter { $0.direction == .across }
            .sorted { $0.number < $1.number }
    }
    var downClues: [CrosswordClue] {
        viewModel.puzzle.clues
            .filter { $0.direction == .down }
            .sorted { $0.number < $1.number }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Across") {
                    ForEach(acrossClues) { clue in clueRow(clue) }
                }
                Section("Down") {
                    ForEach(downClues) { clue in clueRow(clue) }
                }
            }
            .navigationTitle("Clues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func clueRow(_ clue: CrosswordClue) -> some View {
        Button {
            let cells = CrosswordValidator().wordCells(for: clue)
            if let first = cells.first {
                viewModel.selectedRow = first.row
                viewModel.selectedCol = first.col
                viewModel.selectedDirection = clue.direction
            }
            dismiss()
        } label: {
            HStack {
                Text("\(clue.number). \(clue.text)")
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                Spacer()
                if isClueComplete(clue) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func isClueComplete(_ clue: CrosswordClue) -> Bool {
        CrosswordValidator().wordCells(for: clue).allSatisfy { pos in
            viewModel.boardState.cells[pos.row][pos.col].userEntry != nil
        }
    }
}
