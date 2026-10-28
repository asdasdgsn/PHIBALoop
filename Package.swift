// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PHIBALoop",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "PHIBALoopCore", targets: ["PHIBALoopCore"]),
        .executable(name: "PHIBALoop", targets: ["PHIBALoopApp"])
    ],
    targets: [
        .target(name: "PHIBALoopCore"),
        .executableTarget(name: "PHIBALoopApp", dependencies: ["PHIBALoopCore"]),
        .testTarget(name: "PHIBALoopCoreTests", dependencies: ["PHIBALoopCore"])
    ]
)
