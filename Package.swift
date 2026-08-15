// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacroformInbox",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MacroformInboxCore", targets: ["MacroformInboxCore"]),
        .executable(name: "MacroformInbox", targets: ["App"]),
    ],
    targets: [
        .target(name: "MacroformInboxCore"),
        .executableTarget(name: "App", dependencies: ["MacroformInboxCore"], path: "Sources/App"),
        .testTarget(name: "MacroformInboxCoreTests", dependencies: ["MacroformInboxCore"]),
    ],
    swiftLanguageModes: [.v5]
)
