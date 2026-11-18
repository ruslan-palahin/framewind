// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Framewing",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PlayerCore"),
        .executableTarget(name: "Player", dependencies: ["PlayerCore"]),
        .testTarget(name: "PlayerCoreTests", dependencies: ["PlayerCore"]),
        .testTarget(name: "LocalizationTests"),
    ]
)
