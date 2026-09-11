// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SengiriCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SengiriCore", targets: ["SengiriCore"])
    ],
    targets: [
        .target(name: "SengiriCore"),
        .testTarget(name: "SengiriCoreTests", dependencies: ["SengiriCore"])
    ]
)
