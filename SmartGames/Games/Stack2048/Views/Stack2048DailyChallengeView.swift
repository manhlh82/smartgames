import SwiftUI

/// Shows today's Stack 2048 daily challenge info and entry point.
struct Stack2048DailyChallengeView: View {
    @ObservedObject var service: Stack2048DailyChallengeService
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.91, green: 0.66, blue: 0.09),
                                     Color(red: 0.96, green: 0.47, blue: 0.23)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Daily Challenge")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))

                Text("Reach the 256 tile!")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
            }

            // Streak card
            streakCard

            // Completion status
            if service.isCompletedToday() {
                completedBadge
            }

            Spacer()

            // Play button
            Button {
                router.navigate(to: .gamePlay(gameId: "stack2048", context: "daily"))
            } label: {
                Text(service.isCompletedToday() ? "Completed Today" : "Play Daily Challenge")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        service.isCompletedToday()
                            ? AnyShapeStyle(Color.gray.opacity(0.4))
                            : AnyShapeStyle(LinearGradient(
                                colors: [Color(red: 0.91, green: 0.66, blue: 0.09),
                                         Color(red: 0.96, green: 0.47, blue: 0.23)],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(service.isCompletedToday())
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationTitle("Daily Challenge")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var streakCard: some View {
        HStack(spacing: 20) {
            streakBadge(
                value: "\(service.streak.currentStreak)",
                label: "Current Streak",
                icon: "flame.fill",
                color: .orange
            )
            Divider().frame(height: 44)
            streakBadge(
                value: "\(service.streak.bestStreak)",
                label: "Best Streak",
                icon: "trophy.fill",
                color: .yellow
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    private func streakBadge(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Label(value, systemImage: icon)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var completedBadge: some View {
        Label("Completed! Come back tomorrow.", systemImage: "checkmark.seal.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.green)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.green.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
    }
}
