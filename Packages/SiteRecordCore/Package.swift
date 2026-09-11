// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SiteRecordCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SiteRecordCore", targets: ["SiteRecordCore"])
    ],
    targets: [
        .target(name: "SiteRecordCore"),
        .testTarget(name: "SiteRecordCoreTests", dependencies: ["SiteRecordCore"])
    ]
)
