import SwiftUI

struct TimerView: View {
    @Bindable var timer: PomodoroTimer
    @State private var showingSettings = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if showingSettings {
                    SettingsView(timer: timer)
                } else {
                    MainView(timer: timer)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showingSettings)

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
        .frame(width: 300)
    }
}

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

            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < timer.sessionsCompleted % 4 ? phaseColor : Color.secondary.opacity(0.25))
                        .frame(width: 9, height: 9)
                        .animation(.spring, value: timer.sessionsCompleted)
                }
            }

            HStack(spacing: 24) {
                Button(action: timer.reset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Reset")

                Button(action: timer.toggle) {
                    Image(systemName: timer.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(phaseColor)
                }
                .buttonStyle(.borderless)
                .help(timer.isRunning ? "Pause" : "Start")

                Button(action: timer.skip) {
                    Image(systemName: "forward.end.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Skip")
            }

            Text("\(timer.sessionsCompleted) session\(timer.sessionsCompleted == 1 ? "" : "s") today")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Divider()

            Button("Quit Domates") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .padding(24)
    }
}
