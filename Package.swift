// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OpenClawTray",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "OpenClawTray",
            path: "Sources/OpenClawTray"
        )
    ]
)
