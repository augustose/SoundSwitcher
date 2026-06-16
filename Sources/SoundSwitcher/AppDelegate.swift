import Cocoa
import SwiftUI
import CoreAudio
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    var menu: NSMenu!
    var currentProfileIndex = 0
    var bannerWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProfileManager.shared.load()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        registerHotKey()
        updateIcon()
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    func rebuildMenu() {
        menu.removeAllItems()

        // Profiles section
        let header = NSMenuItem(title: "Profiles", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        for (i, profile) in ProfileManager.shared.profiles.enumerated() {
            let available = ProfileManager.shared.isAvailable(profile)
            let item = NSMenuItem(
                title: profile.name + (available ? "" : " ⚠️"),
                action: #selector(selectProfile(_:)),
                keyEquivalent: ""
            )
            item.representedObject = i
            item.target = self
            item.state = (i == currentProfileIndex) ? NSControl.StateValue.on : NSControl.StateValue.off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Devices info
        let outID = AudioDeviceManager.shared.defaultOutputDeviceID()
        let inID = AudioDeviceManager.shared.defaultInputDeviceID()
        let outName = AudioDeviceManager.shared.outputDevices().first { $0.id == outID }?.name ?? "—"
        let inName = AudioDeviceManager.shared.inputDevices().first { $0.id == inID }?.name ?? "—"

        let outItem = NSMenuItem(title: "↑  \(outName)", action: nil, keyEquivalent: "")
        outItem.isEnabled = false
        menu.addItem(outItem)

        let inItem = NSMenuItem(title: "🎙  \(inName)", action: nil, keyEquivalent: "")
        inItem.isEnabled = false
        menu.addItem(inItem)

        menu.addItem(.separator())
        let configItem = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        configItem.target = self
        menu.addItem(configItem)
        menu.addItem(.separator())
        let shortcutInfo = NSMenuItem(title: "Shortcut: ⌥⌘S", action: nil, keyEquivalent: "")
        shortcutInfo.isEnabled = false
        menu.addItem(shortcutInfo)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc func selectProfile(_ sender: NSMenuItem) {
        guard let index = sender.representedObject as? Int else { return }
        applyProfile(at: index)
    }

    @objc func openPreferences() {
        PreferencesWindowController.show()
    }

    // MARK: - Profile Application

    func applyProfile(at index: Int) {
        let profiles = ProfileManager.shared.profiles
        guard index < profiles.count else { return }
        let profile = profiles[index]

        let (output, input, outputFallback, inputFallback) = ProfileManager.shared.applyProfile(profile)
        currentProfileIndex = index
        updateIcon()
        showBanner(
            profileName: profile.name,
            outputName: output.name,
            inputName: input.name,
            outputFallback: outputFallback,
            inputFallback: inputFallback
        )
    }

    func cycleToNextProfile() {
        let profiles = ProfileManager.shared.profiles
        guard !profiles.isEmpty else { return }
        var next = (currentProfileIndex + 1) % profiles.count
        var tried = 0
        while !ProfileManager.shared.isAvailable(profiles[next]) {
            next = (next + 1) % profiles.count
            tried += 1
            if tried >= profiles.count { return }
        }
        applyProfile(at: next)
    }

    // MARK: - Icon

    func updateIcon() {
        let outID = AudioDeviceManager.shared.defaultOutputDeviceID()
        let outputs = AudioDeviceManager.shared.outputDevices()
        let name = outputs.first { $0.id == outID }?.name ?? "Audio"
        let profile = ProfileManager.shared.profiles.indices.contains(currentProfileIndex)
            ? ProfileManager.shared.profiles[currentProfileIndex].name : ""

        if let button = statusItem.button {
            button.image = makeSoundSwitcherIcon(size: 18)
            button.title = ""
            button.toolTip = profile.isEmpty ? name : "\(profile): \(name)"
        }
    }

    // MARK: - Banner (kept alive with strong ref to avoid crash)

    func showBanner(profileName: String, outputName: String, inputName: String,
                    outputFallback: Bool = false, inputFallback: Bool = false) {
        bannerWindow?.orderOut(nil)
        bannerWindow = nil

        let screen = statusItem.button?.window?.screen ?? NSScreen.main
        guard let screen = screen else { return }
        let sf = screen.frame

        // Use SwiftUI for auto-sizing
        let swiftUIView = BannerSwiftUIView(
            profileName: profileName,
            outputName: outputName,
            inputName: inputName,
            outputFallback: outputFallback,
            inputFallback: inputFallback
        )
        let hosting = NSHostingView(rootView: swiftUIView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        let fittingSize = hosting.fittingSize
        let width = max(fittingSize.width + 32, 260)
        let height = fittingSize.height + 20
        let x = sf.midX - width / 2
        let y = sf.maxY - height - 6

        let win = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]
        win.contentView = NSHostingView(rootView: swiftUIView)
        win.orderFrontRegardless()
        bannerWindow = win

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.bannerWindow?.orderOut(nil)
            self?.bannerWindow = nil
        }
    }

    // MARK: - Hotkey ⌥⌘S

    func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("SWCH".fourCharCode)
        hotKeyID.id = 1

        let modifiers: UInt32 = UInt32(optionKey | cmdKey)
        let keyCode: UInt32 = UInt32(kVK_ANSI_S)

        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr { return }

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, _, userData) -> OSStatus in
            let d = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            DispatchQueue.main.async { d.cycleToNextProfile() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }
}

// MARK: - Banner SwiftUI View

struct BannerSwiftUIView: View {
    let profileName: String
    let outputName: String
    let inputName: String
    let outputFallback: Bool
    let inputFallback: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(profileName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Divider()
                .background(Color.white.opacity(0.3))

            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(outputFallback ? .orange : .white.opacity(0.9))
                    .font(.system(size: 12))
                Text(outputName)
                    .font(.system(size: 12))
                    .foregroundColor(outputFallback ? .orange : .white.opacity(0.9))
                if outputFallback {
                    Text("(fallback)")
                        .font(.system(size: 10))
                        .foregroundColor(.orange.opacity(0.8))
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .foregroundColor(inputFallback ? .orange : .white.opacity(0.9))
                    .font(.system(size: 12))
                Text(inputName)
                    .font(.system(size: 12))
                    .foregroundColor(inputFallback ? .orange : .white.opacity(0.9))
                if inputFallback {
                    Text("(fallback)")
                        .font(.system(size: 10))
                        .foregroundColor(.orange.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.82))
        )
    }
}

extension String {
    var fourCharCode: FourCharCode {
        return self.utf16.reduce(0) { $0 << 8 + FourCharCode($1) }
    }
}
