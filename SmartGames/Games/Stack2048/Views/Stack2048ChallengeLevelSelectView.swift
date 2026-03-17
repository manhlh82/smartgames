import SwiftUI

/// Grid of 50 challenge levels — tap to start a level, locked levels are grayed out.
struct Stack2048ChallengeLevelSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter

    let persistence: PersistenceService

    @State private var progress = Stack2048Progress()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(1...50, id: \.self) { level in
                    LevelCell(
                        level: level,
                        stars: progress.challengeStars[level] ?? 0,
                        isUnlocked: isUnlocked(level)
                    ) {
                        router.navigate(to: .gamePlay(gameId: "stack2048", context: "challenge-\(level)"))
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Challenge Levels")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            progress = persistence.load(Stack2048Progress.self, key: PersistenceService.Keys.stack2048Progress) ?? Stack2048Progress()
        }
    }

    private func isUnlocked(_ level: Int) -> Bool {
        if level == 1 { return true }
        return (progress.challengeStars[level - 1] ?? 0) > 0
    }
}

// MARK: - Level Cell

private struct LevelCell: View {
    let level: Int
    let stars: Int
    let isUnlocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: { if isUnlocked { onTap() } }) {
            VStack(spacing: 4) {
                Text("\(level)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(isUnlocked ? .primary : .secondary)

                StarsRow(stars: stars, isUnlocked: isUnlocked)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .opacity(isUnlocked ? 1.0 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    private var cellBackground: some View {
        Group {
            if stars == 3 {
                LinearGradient(
                    colors: [Color(red: 0.91, green: 0.66, blue: 0.09).opacity(0.25),
                             Color(red: 0.96, green: 0.47, blue: 0.23).opacity(0.15)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            } else {
                Color(.secondarySystemBackground)
            }
        }
    }

    private var borderColor: Color {
        if stars == 3 { return Color(red: 0.91, green: 0.66, blue: 0.09).opacity(0.5) }
        if stars > 0  { return Color.accentColor.opacity(0.3) }
        return Color.clear
    }
}

// MARK: - Stars Row

private struct StarsRow: View {
    let stars: Int
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 2) {
            if isUnlocked {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= stars ? "star.fill" : "star")
                        .font(.system(size: 9))
                        .foregroundStyle(i <= stars
                            ? Color(red: 0.91, green: 0.66, blue: 0.09)
                            : Color.secondary.opacity(0.4))
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
