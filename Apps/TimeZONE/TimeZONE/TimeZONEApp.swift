import SwiftUI

@main
struct TimeZONEApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // ATT の確認を出してから広告 SDK を始める。
                .task { await Ads.start() }
        }
    }
}
