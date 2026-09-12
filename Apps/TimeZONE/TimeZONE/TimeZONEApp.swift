import GoogleMobileAds
import SwiftUI

@main
struct TimeZONEApp: App {
    init() {
        // 広告の読み込みに時間がかかるので、起動時に初期化しておく。
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
