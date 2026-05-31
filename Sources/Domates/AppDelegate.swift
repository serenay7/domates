import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let pomodoroTimer = PomodoroTimer()
    private var tickTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        startStatusBarTick()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 430)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: TimerView(timer: pomodoroTimer)
        )

        updateStatusBar()

        guard let button = statusItem.button else { return }
        button.action = #selector(togglePopover(_:))
        button.target = self
    }

    private func startStatusBarTick() {
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateStatusBar() }
        }
        RunLoop.main.add(tickTimer!, forMode: .common)
    }

    private func updateStatusBar() {
        statusItem.button?.title = "🍅 \(pomodoroTimer.timeString)"
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
