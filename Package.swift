// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacKey",
    platforms: [.macOS(.v14)],
    products: [.library(name: "MacKeyCore", targets: ["MacKeyCore"]), .executable(name: "MacKey", targets: ["MacKey"])],
    targets: [
        .target(name: "MacKeyCore"),
        .executableTarget(name: "MacKey", dependencies: ["MacKeyCore"]),
        .testTarget(name: "MacKeyCoreTests", dependencies: ["MacKeyCore"])
    ]
)
