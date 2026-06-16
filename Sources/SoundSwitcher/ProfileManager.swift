import Foundation
import CoreAudio

struct Profile: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var outputDevice: String   // substring match, case-insensitive
    var inputDevice: String

    enum CodingKeys: String, CodingKey {
        case id, name, outputDevice, inputDevice
    }
}

struct ProfilesConfig: Codable {
    var profiles: [Profile]
}

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published var profiles: [Profile] = []

    private let configURL: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/soundswitcher")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("profiles.json")
    }()

    func load() {
        if FileManager.default.fileExists(atPath: configURL.path),
           let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(ProfilesConfig.self, from: data) {
            profiles = config.profiles
        } else {
            profiles = defaultProfiles()
            save()
        }
    }

    func save() {
        let config = ProfilesConfig(profiles: profiles)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(config) {
            try? data.write(to: configURL)
        }
    }

    /// Tries to resolve profile devices. Returns actual devices used (may differ if fallback needed).
    func applyProfile(_ profile: Profile) -> (output: AudioDevice, input: AudioDevice, outputFallback: Bool, inputFallback: Bool) {
        let outputs = AudioDeviceManager.shared.outputDevices()
        let inputs = AudioDeviceManager.shared.inputDevices()

        let wantedOutput = outputs.first { $0.name.lowercased().contains(profile.outputDevice.lowercased()) }
        let wantedInput = inputs.first { $0.name.lowercased().contains(profile.inputDevice.lowercased()) }

        let currentOutputID = AudioDeviceManager.shared.defaultOutputDeviceID()
        let currentInputID = AudioDeviceManager.shared.defaultInputDeviceID()

        let output = wantedOutput ?? outputs.first { $0.id == currentOutputID } ?? outputs.first!
        let input = wantedInput ?? inputs.first { $0.id == currentInputID } ?? inputs.first!

        AudioDeviceManager.shared.setDefaultOutputDevice(output.id)
        AudioDeviceManager.shared.setDefaultInputDevice(input.id)

        return (output, input, wantedOutput == nil, wantedInput == nil)
    }

    func isAvailable(_ profile: Profile) -> Bool {
        let outputs = AudioDeviceManager.shared.outputDevices()
        let inputs = AudioDeviceManager.shared.inputDevices()
        let hasOutput = outputs.contains { $0.name.lowercased().contains(profile.outputDevice.lowercased()) }
        let hasInput = inputs.contains { $0.name.lowercased().contains(profile.inputDevice.lowercased()) }
        return hasOutput && hasInput
    }

    private func defaultProfiles() -> [Profile] {
        [
            Profile(name: "MacBook", outputDevice: "built-in", inputDevice: "built-in"),
            Profile(name: "Headset", outputDevice: "headphone", inputDevice: "headphone"),
            Profile(name: "AirPods", outputDevice: "airpod", inputDevice: "airpod"),
            Profile(name: "Office", outputDevice: "built-in", inputDevice: "external"),
        ]
    }
}
