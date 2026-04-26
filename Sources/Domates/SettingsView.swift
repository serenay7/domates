import SwiftUI

struct SettingsView: View {
    @Bindable var timer: PomodoroTimer

    var body: some View {
        VStack(spacing: 24) {
            Text("Durations")
                .font(.headline)

            VStack(spacing: 16) {
                DurationRow(label: "Focus", color: .red,   minutes: $timer.workMinutes,       range: 1...120)
                DurationRow(label: "Short Break", color: .green, minutes: $timer.shortBreakMinutes, range: 1...60)
                DurationRow(label: "Long Break",  color: .blue,  minutes: $timer.longBreakMinutes,  range: 1...60)
            }

            Text("Changes apply after the current session ends.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct DurationRow: View {
    let label: String
    let color: Color
    @Binding var minutes: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            Stepper(value: $minutes, in: range) {
                Text("\(minutes) min")
                    .monospacedDigit()
                    .frame(width: 52, alignment: .trailing)
            }
        }
    }
}
