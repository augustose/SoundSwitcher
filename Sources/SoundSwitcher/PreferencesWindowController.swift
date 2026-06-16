import Cocoa
import SwiftUI

class PreferencesWindowController: NSWindowController {
    static var shared: PreferencesWindowController?

    static func show() {
        if let existing = shared {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = PreferencesWindowController()
        shared = controller
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    init() {
        let hostingView = NSHostingView(rootView: PreferencesView())
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 360),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "SoundSwitcher — Perfiles"
        win.contentView = hostingView
        win.center()
        win.setFrameAutosaveName("PreferencesWindow")
        win.minSize = NSSize(width: 440, height: 300)
        super.init(window: win)
        win.delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }
}

extension PreferencesWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        ProfileManager.shared.save()
        PreferencesWindowController.shared = nil
    }
}
