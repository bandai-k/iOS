// swift-tools-version: 5.9
import PackageDescription

// 広告まわりを 2 つのアプリで使い回すためのパッケージ。
// 広告 SDK が iOS 専用なので、このパッケージも iOS 専用。macOS では動かないため、
// `swift test` の対象にはならない (テスト対象は Tests ディレクトリを持つパッケージだけ)。
let package = Package(
    name: "BannerAds",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "BannerAds", targets: ["BannerAds"])
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "12.0.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "BannerAds",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                .product(name: "GoogleUserMessagingPlatform", package: "swift-package-manager-google-user-messaging-platform")
            ]
        )
    ]
)
