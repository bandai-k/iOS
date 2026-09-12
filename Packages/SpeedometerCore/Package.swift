// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeedometerCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SpeedometerCore", targets: ["SpeedometerCore"])
    ],
    targets: [
        .target(name: "SpeedometerCore"),
        .testTarget(name: "SpeedometerCoreTests", dependencies: ["SpeedometerCore"])
    ]
)
