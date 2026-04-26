import Foundation
import AppKit
import UserNotifications
import Observation

enum TimerPhase: String {
    case work = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    var duration: TimeInterval {
        switch self {
        case .work:       return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak:  return 15 * 60
        }
    }

    var label: String { rawValue }
}

@MainActor
@Observable
final class PomodoroTimer {
    var phase: TimerPhase = .work
    var timeRemaining: TimeInterval = TimerPhase.work.duration
    var isRunning = false
    var sessionsCompleted = 0

    private var timer: Timer?

    var timeString: String {
        String(format: "%02d:%02d", Int(timeRemaining) / 60, Int(timeRemaining) % 60)
    }

    var progress: Double {
        1.0 - timeRemaining / phase.duration
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        timeRemaining = phase.duration
    }

    func skip() {
        pause()
        advance()
    }

    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            complete()
        }
    }

    private func complete() {
        pause()
        NSSound.beep()
        if phase == .work {
            sessionsCompleted += 1
            phase = sessionsCompleted % 4 == 0 ? .longBreak : .shortBreak
        } else {
            phase = .work
        }
        timeRemaining = phase.duration
        sendNotification()
    }

    private func advance() {
        if phase == .work {
            phase = sessionsCompleted % 4 == 0 ? .longBreak : .shortBreak
        } else {
            phase = .work
        }
        timeRemaining = phase.duration
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🍅 Domates"
        content.body = phase == .work ? "Time to focus!" : "Take a \(phase.label.lowercased())!"
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
