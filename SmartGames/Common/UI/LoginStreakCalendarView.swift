import SwiftUI

/// 7-day visual streak calendar — shows claimed, graced, upcoming, and today states.
/// Displayed in DailyLoginPopupView above the reward amount.
struct LoginStreakCalendarView: View {
    /// Current streak day within the 7-day cycle (1–7).
    let streakDayInCycle: Int
    /// True if a grace day was used this cycle.
    let graceUsed: Bool

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { day in
                dayCircle(for: day)
            }
        }
    }

    @ViewBuilder
    private func dayCircle(for day: Int) -> some View {
        let state = dayState(for: day)
        ZStack {
            Circle()
                .fill(backgroundColor(for: state))
                .frame(width: 34, height: 34)
                .overlay(
                    Circle()
                        .stroke(borderColor(for: state), lineWidth: state == .today ? 2 : 0)
                )

            icon(for: state)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(iconColor(for: state))
        }
    }

    private enum DayState { case claimed, graced, today, upcoming }

    private func dayState(for day: Int) -> DayState {
        if day < streakDayInCycle { return graceUsed && day == streakDayInCycle - 1 ? .graced : .claimed }
        if day == streakDayInCycle { return .today }
        return .upcoming
    }

    @ViewBuilder
    private func icon(for state: DayState) -> some View {
        switch state {
        case .claimed:  Image(systemName: "checkmark")
        case .graced:   Image(systemName: "exclamationmark")
        case .today:    Image(systemName: "star.fill")
        case .upcoming: Text("").frame(width: 1)
        }
    }

    private func backgroundColor(for state: DayState) -> Color {
        switch state {
        case .claimed:  return .green.opacity(0.8)
        case .graced:   return .yellow.opacity(0.8)
        case .today:    return .accentColor
        case .upcoming: return Color.secondary.opacity(0.15)
        }
    }

    private func borderColor(for state: DayState) -> Color {
        state == .today ? .accentColor : .clear
    }

    private func iconColor(for state: DayState) -> Color {
        switch state {
        case .claimed, .graced: return .white
        case .today:            return .white
        case .upcoming:         return .clear
        }
    }
}
