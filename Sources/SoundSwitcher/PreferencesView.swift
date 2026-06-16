import SwiftUI
import CoreAudio

struct PreferencesView: View {
    @ObservedObject var manager = ProfileManager.shared
    @State private var selectedProfileID: UUID? = nil
    @State private var outputDevices: [AudioDevice] = []
    @State private var inputDevices: [AudioDevice] = []

    var body: some View {
        HSplitView {
            // Left: profile list
            VStack(spacing: 0) {
                List(selection: $selectedProfileID) {
                    ForEach($manager.profiles) { $profile in
                        HStack {
                            Image(systemName: iconName(for: profile.outputDevice))
                                .frame(width: 20)
                            Text(profile.name)
                            Spacer()
                            if !isAvailable(profile) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                        .tag(profile.id)
                    }
                    .onMove(perform: moveProfile)
                    .onDelete(perform: deleteProfile)
                }
                .listStyle(.sidebar)

                Divider()

                HStack(spacing: 4) {
                    Button(action: addProfile) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                    .help("Add profile")

                    Button(action: deleteSelected) {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedProfileID == nil)
                    .help("Delete profile")

                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .frame(minWidth: 160, idealWidth: 180, maxWidth: 220)

            // Right: profile detail
            if let id = selectedProfileID, let idx = manager.profiles.firstIndex(where: { $0.id == id }) {
                ProfileDetailView(
                    profile: $manager.profiles[idx],
                    outputDevices: outputDevices,
                    inputDevices: inputDevices
                )
            } else {
                VStack {
                    Spacer()
                    Text("Select a profile")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            outputDevices = AudioDeviceManager.shared.outputDevices()
            inputDevices = AudioDeviceManager.shared.inputDevices()
            if selectedProfileID == nil {
                selectedProfileID = manager.profiles.first?.id
            }
        }
        .onChange(of: manager.profiles) { _ in
            manager.save()
        }
    }

    private func isAvailable(_ profile: Profile) -> Bool {
        outputDevices.contains { $0.name.lowercased().contains(profile.outputDevice.lowercased()) }
        && inputDevices.contains { $0.name.lowercased().contains(profile.inputDevice.lowercased()) }
    }

    private func iconName(for devicePattern: String) -> String {
        let lower = devicePattern.lowercased()
        if lower.contains("airpod") { return "airpodspro" }
        if lower.contains("headphone") { return "headphones" }
        if lower.contains("built-in") || lower.contains("macbook") { return "laptopspeaker" }
        if lower.contains("speaker") { return "hifispeaker" }
        if lower.contains("hdmi") || lower.contains("display") { return "display" }
        return "speaker.wave.2"
    }

    private func addProfile() {
        let p = Profile(name: "New profile", outputDevice: "built-in", inputDevice: "built-in")
        manager.profiles.append(p)
        selectedProfileID = p.id
    }

    private func deleteProfile(at offsets: IndexSet) {
        manager.profiles.remove(atOffsets: offsets)
    }

    private func deleteSelected() {
        guard let id = selectedProfileID,
              let idx = manager.profiles.firstIndex(where: { $0.id == id }) else { return }
        manager.profiles.remove(at: idx)
        selectedProfileID = manager.profiles.first?.id
    }

    private func moveProfile(from: IndexSet, to: Int) {
        manager.profiles.move(fromOffsets: from, toOffset: to)
    }
}

struct ProfileDetailView: View {
    @Binding var profile: Profile
    let outputDevices: [AudioDevice]
    let inputDevices: [AudioDevice]

    var body: some View {
        Form {
            Section {
                TextField("Profile name", text: $profile.name)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Name")
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            Divider().padding(.vertical, 4)

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output device (speaker)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("", selection: $profile.outputDevice) {
                        ForEach(outputDevices, id: \.id) { device in
                            Text(device.name).tag(substringKey(device.name))
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    if !outputDevices.contains(where: { $0.name.lowercased().contains(profile.outputDevice.lowercased()) }) {
                        Label("Device not connected — current device will be used as fallback", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Divider().padding(.vertical, 4)

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input device (microphone)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("", selection: $profile.inputDevice) {
                        ForEach(inputDevices, id: \.id) { device in
                            Text(device.name).tag(substringKey(device.name))
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    if !inputDevices.contains(where: { $0.name.lowercased().contains(profile.inputDevice.lowercased()) }) {
                        Label("Device not connected — current device will be used as fallback", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Divider().padding(.vertical, 4)

            Text("Name is matched as a case-insensitive substring. Connect the device to see it in the list.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(minWidth: 300)
    }

    private func substringKey(_ name: String) -> String {
        name.lowercased()
    }
}

#Preview {
    PreferencesView()
        .frame(width: 520, height: 360)
}
