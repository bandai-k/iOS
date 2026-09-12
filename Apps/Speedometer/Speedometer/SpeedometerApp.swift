import GoogleMobileAds
import SwiftUI

@main
struct SpeedometerApp: App {
    init() {
        // 広告の読み込みに時間がかかるので、起動時に初期化しておく。
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            SpeedometerScreen()
        }
    }
}
