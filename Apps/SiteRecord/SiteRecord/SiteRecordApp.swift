import SwiftUI

@main
struct SiteRecordApp: App {
    /// テスト実行中か。
    ///
    /// 単体テストはアプリ本体を起動して行うため、そのままだとカメラと購入の初期化が走り、
    /// StoreKit のテスト用セッションが用意される前に本物の StoreKit へ問い合わせてしまう
    /// （サインインを求めるダイアログが出てテストが止まる）。テスト中は画面を出さない。
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var body: some Scene {
        WindowGroup {
            if isRunningTests {
                Color.clear
            } else {
                CameraScreen()
            }
        }
    }
}
