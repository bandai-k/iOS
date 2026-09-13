import BannerAds
import SwiftUI

@main
struct SpeedometerApp: App {
    var body: some Scene {
        WindowGroup {
            SpeedometerScreen()
                // ATT の確認を出してから広告 SDK を始める。
                .task { await Ads.start() }
        }
    }
}
