# SoundSwitcher

A lightweight macOS menu bar app that lets you switch audio input/output devices instantly using a keyboard shortcut.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-arm64-green)

## Features

- **⌥⌘S** — cycle through your configured audio profiles
- **Menu bar icon** — shows at a glance which profile is active (with tooltip)
- **Profiles** — each profile sets both an output device (speaker) and an input device (microphone)
- **Fallback** — if a device in a profile isn't connected, automatically uses the current device and tells you in the notification
- **Preferences UI** — configure profiles with a native macOS panel (no config files to edit)
- **Notification banner** — shows the active profile and device names for 2.5 seconds after switching

## Installation

### Option A: Download (recommended)

1. Download `SoundSwitcher-x.x.x-arm64.zip` from the [latest release](../../releases/latest)
2. Unzip and drag `SoundSwitcher.app` to your `/Applications` folder
3. Open it — macOS may ask you to confirm opening an app from an unidentified developer:
   - Go to **System Settings → Privacy & Security** and click **Open Anyway**
4. The app icon appears in the menu bar

> **Requires:** macOS 13 Ventura or later · Apple Silicon (M1/M2/M3/M4)

### Option B: Build from source

**Requirements:** Xcode Command Line Tools (`xcode-select --install`)

```bash
git clone https://github.com/YOUR_USER/SoundSwitcher.git
cd SoundSwitcher
make install   # builds, bundles, and copies to /Applications
```

## Usage

### Keyboard shortcut

Press **⌥⌘S** (Option + Command + S) to cycle to the next available profile. A banner appears near the top of the screen showing the active devices.

### Menu bar

Click the SoundSwitcher icon in the menu bar to:
- See all configured profiles (✓ marks the active one, ⚠️ marks unavailable)
- Select a profile directly
- Open **Preferences** (⌘,) to manage profiles

### Configuring profiles

Open **Preferences** from the menu bar icon. Each profile has:
- **Name** — shown in the menu and notification banner
- **Output device** — speaker / headphones / monitor (matched by name substring)
- **Input device** — microphone (matched by name substring)

Profiles with unavailable devices show a ⚠️ warning and are skipped when cycling with ⌥⌘S (a fallback device is used if you select one directly).

**Example profiles:**

| Profile | Output | Input |
|---------|--------|-------|
| MacBook | Built-in Speakers | Built-in Microphone |
| Headset | Plantronics BT600 | Plantronics BT600 |
| AirPods | AirPods Pro | AirPods Pro |
| Office | Built-in Speakers | Focusrite USB |

## Auto-launch at login

Open **System Settings → General → Login Items** and add `SoundSwitcher.app`.

## Building a release

```bash
git tag v1.0.0
make release   # produces SoundSwitcher-1.0.0-arm64.zip
```

Upload the `.zip` to a new GitHub Release.

## License

MIT
