// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacBetterFanControl",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MacBetterFanControl", targets: ["MacBetterFanControl"])
    ],
    targets: [
        .executableTarget(name: "MacBetterFanControl")
    ]
)
