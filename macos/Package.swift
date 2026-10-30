// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PillReminder",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PillReminder",
            path: "Sources/PillReminder",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Speech"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Network"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("Security"),
            ]
        )
    ]
)
