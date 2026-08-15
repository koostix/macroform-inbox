// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MusicProjectsOrganizer",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MusicProjectsOrganizerCore", targets: ["MusicProjectsOrganizerCore"]),
        .executable(name: "MusicProjectsOrganizer", targets: ["App"]),
    ],
    targets: [
        .target(name: "MusicProjectsOrganizerCore"),
        .executableTarget(
            name: "App",
            dependencies: ["MusicProjectsOrganizerCore"],
            path: "Sources/App",
            exclude: ["Info.plist"]
        ),
        .testTarget(name: "MusicProjectsOrganizerCoreTests", dependencies: ["MusicProjectsOrganizerCore"]),
    ],
    swiftLanguageModes: [.v5]
)
