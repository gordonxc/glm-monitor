// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GLMMonitor",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "GLMMonitor",
            path: "Sources/GLMMonitor"
        )
    ]
)
