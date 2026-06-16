// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SoundSwitcher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SoundSwitcher",
            path: "Sources/SoundSwitcher",
            exclude: ["Info.plist"],
            linkerSettings: [
                .linkedFramework("CoreAudio"),
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit"),
            ]
        )
    ]
)
