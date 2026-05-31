import SwiftUI

private enum AppTab { case timer, activity }

struct TimerView: View {
    @Bindable var timer: PomodoroTimer
    @State private var tab: AppTab = .timer
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Content area ──────────────────────────────────────────────
            ZStack(alignment: .topTrailing) {
                Group {
                    if showingSettings {
                        SettingsView(timer: timer)
                    } else if tab == .timer {
                        MainView(timer: timer)
                    } else {
                        ActivityView(store: timer.store)
                    }
                }
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.18), value: showingSettings)
                .animation(.easeInOut(duration: 0.18), value: tab)

                Button {
                    showingSettings.toggle()
                } label: {
                    Image(systemName: showingSettings ? "xmark" : "gearshape")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .padding(14)
            }

            Divider()

            // ── Tab bar ───────────────────────────────────────────────────
            HStack(spacing: 4) {
                TabPill(icon: "timer",        label: "Timer",    active: tab == .timer    && !showingSettings) {
                    tab = .timer; showingSettings = false
                }
                TabPill(icon: "chart.bar.fill", label: "Activity", active: tab == .activity && !showingSettings) {
                    tab = .activity; showingSettings = false
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 300)
    }
}

// MARK: - Tab pill button

private struct TabPill: View {
    let icon: String
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.caption)
            .fontWeight(active ? .semibold : .regular)
            .foregroundStyle(active ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(active ? Color.secondary.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - Main timer content

private struct MainView: View {
    @Bindable var timer: PomodoroTimer

    private var phaseColor: Color {
        switch timer.phase {
        case .work:       return .red
        case .shortBreak: return .green
        case .longBreak:  return .blue
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(timer.phase.label)
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(phaseColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.8), value: timer.progress)

                Text(timer.timeString)
                    .font(.system(size: 52, weight: .thin, design: .monospaced))
                    .contentTransition(.numericText())
            }
            .frame(width: 190, height: 190)

            // Session dots
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < timer.sessionsCompleted % 4 ? phaseColor : Color.secondary.opacity(0.25))
                        .frame(width: 9, height: 9)
                        .animation(.spring, value: timer.sessionsCompleted)
                }
            }

            // Controls
            HStack(spacing: 24) {
                Button(action: timer.reset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2).foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless).help("Reset")

                Button(action: timer.toggle) {
                    Image(systemName: timer.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52)).foregroundStyle(phaseColor)
                }
                .buttonStyle(.borderless).help(timer.isRunning ? "Pause" : "Start")

                Button(action: timer.finishEarly) {
                    Image(systemName: "forward.end.fill")
                        .font(.title2).foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help(timer.phase == .work ? "Finish session early (logs elapsed time)" : "Skip break")
            }

            // Session count + End Day
            HStack(spacing: 6) {
                Text("\(timer.sessionsCompleted) session\(timer.sessionsCompleted == 1 ? "" : "s") today")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                if timer.sessionsCompleted > 0 || timer.phase != .work {
                    Text("·").font(.caption).foregroundStyle(.tertiary)
                    Button("End day") { timer.endDay() }
                        .buttonStyle(.borderless)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Divider()

            Button("Quit Domates") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(24)
    }
}
