import SwiftUI

@main
struct SiteRecordApp: App {
    var body: some Scene {
        WindowGroup {
            CameraScreen()
                // 記録写真は縦で撮る運用なので、画面もダーク固定にしてカメラに集中させる。
                .preferredColorScheme(.dark)
        }
    }
}
