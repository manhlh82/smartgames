import SwiftUI

/// Single cell in the Drop Rush level select grid.
/// Displays level number, star rating, and locked/unlocked state.
struct LevelCellView: View {
    let level: Int
    let stars: Int
    let isUnlocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                VStack(spacing: 4) {
                    Text("\(level)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isUnlocked ? .primary : .secondary)

                    HStack(spacing: 2) {
                        ForEach(1...3, id: \.self) { i in
                            Image(systemName: i <= stars ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(i <= stars ? .yellow : Color.gray.opacity(0.3))
                        }
                    }
                }
                .frame(width: 56, height: 60)
                .background(isUnlocked ? Color.accentColor.opacity(0.12) : Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}
