import Foundation
import AppKit
import UserNotifications
import Observation

enum TimerPhase: String {
    case work = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    var label: String { rawValue }
}

@MainActor
@Observable
final class PomodoroTimer {
    var phase: TimerPhase = .work
    var timeRemaining: TimeInterval
    var isRunning = false
    var sessionsCompleted = 0

    var workMinutes: Int {
        didSet {
            UserDefaults.standard.set(workMinutes, forKey: "workMinutes")
            if phase == .work && !isRunning { timeRemaining = duration(for: .work) }
        }
    }
    var shortBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(shortBreakMinutes, forKey: "shortBreakMinutes")
            if phase == .shortBreak && !isRunning { timeRemaining = duration(for: .shortBreak) }
        }
    }
    var longBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(longBreakMinutes, forKey: "longBreakMinutes")
            if phase == .longBreak && !isRunning { timeRemaining = duration(for: .longBreak) }
        }
    }
    var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    private var timer: Timer?

    init() {
        let ud = UserDefaults.standard
        let wm = ud.object(forKey: "workMinutes")       != nil ? ud.integer(forKey: "workMinutes")       : 25
        let sb = ud.object(forKey: "shortBreakMinutes") != nil ? ud.integer(forKey: "shortBreakMinutes") : 5
        let lb = ud.object(forKey: "longBreakMinutes")  != nil ? ud.integer(forKey: "longBreakMinutes")  : 15
        workMinutes           = wm
        shortBreakMinutes     = sb
        longBreakMinutes      = lb
        soundEnabled          = ud.object(forKey: "soundEnabled")          != nil ? ud.bool(forKey: "soundEnabled")          : true
        notificationsEnabled  = ud.object(forKey: "notificationsEnabled")  != nil ? ud.bool(forKey: "notificationsEnabled")  : true
        timeRemaining         = TimeInterval(wm * 60)
    }

    func duration(for phase: TimerPhase) -> TimeInterval {
        switch phase {
        case .work:       return TimeInterval(workMinutes * 60)
        case .shortBreak: return TimeInterval(shortBreakMinutes * 60)
        case .longBreak:  return TimeInterval(longBreakMinutes * 60)
        }
    }

    var timeString: String {
        String(format: "%02d:%02d", Int(timeRemaining) / 60, Int(timeRemaining) % 60)
    }

    var progress: Double {
        1.0 - timeRemaining / duration(for: phase)
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
        timeRemaining = duration(for: phase)
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
        if phase == .work {
            sessionsCompleted += 1
            phase = sessionsCompleted % 4 == 0 ? .longBreak : .shortBreak
        } else {
            phase = .work
        }
        timeRemaining = duration(for: phase)
        if soundEnabled { playBell() }
        if notificationsEnabled { sendNotification() }
    }

    private func playBell() {
        // "Glass" is a soft, clear bell — falls back to system beep if unavailable
        if let sound = NSSound(named: NSSound.Name("Glass")) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    private func advance() {
        if phase == .work {
            phase = sessionsCompleted % 4 == 0 ? .longBreak : .shortBreak
        } else {
            phase = .work
        }
        timeRemaining = duration(for: phase)
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
