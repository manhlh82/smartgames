import SwiftUI

/// Daily login streak popup — shown when DailyLoginRewardService.pendingReward is set.
/// Displays streak day, gold earned, and optional diamond bonus (day 7+).
struct DailyLoginPopupView: View {
    let reward: LoginReward
    let onClaim: () -> Void

    @State private var revealed = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                VStack(spacing: 4) {
                    Text("Day \(reward.streakDay)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text("Daily Reward")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                // Streak dots (7-day cycle)
                HStack(spacing: 6) {
                    ForEach(1...7, id: \.self) { day in
                        let filled = day <= (reward.streakDay % 7 == 0 ? 7 : reward.streakDay % 7)
                        Circle()
                            .fill(filled ? Color.yellow : Color.secondary.opacity(0.25))
                            .frame(width: 10, height: 10)
                            .overlay(
                                day == 7
                                    ? Circle().stroke(Color.cyan.opacity(0.7), lineWidth: 1.5)
                                    : nil
                            )
                    }
                }

                // Rewards
                VStack(spacing: 10) {
                    // Gold
                    HStack(spacing: 10) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.yellow)
                            .scaleEffect(revealed ? 1.0 : 0.3)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15), value: revealed)
                        Text("+\(reward.goldAmount) Gold")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .opacity(revealed ? 1.0 : 0)
                            .animation(.easeOut.delay(0.15), value: revealed)
                    }

                    // Diamond bonus (day 7)
                    if reward.diamondAmount > 0 {
                        HStack(spacing: 10) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.cyan)
                                .scaleEffect(revealed ? 1.0 : 0.3)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.35), value: revealed)
                            Text("+\(reward.diamondAmount) Diamond")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.cyan)
                                .opacity(revealed ? 1.0 : 0)
                                .animation(.easeOut.delay(0.35), value: revealed)
                        }

                        Text("Week complete bonus!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.cyan.opacity(0.8))
                            .opacity(revealed ? 1.0 : 0)
                            .animation(.easeOut.delay(0.5), value: revealed)
                    }
                }
                .padding(.vertical, 8)

                // Claim button
                Button(action: onClaim) {
                    Label("Claim", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .opacity(revealed ? 1.0 : 0)
                .animation(.easeOut.delay(0.4), value: revealed)
            }
            .padding(28)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 24)
            .padding(.horizontal, 28)
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                revealed = true
            }
        }
    }
}
