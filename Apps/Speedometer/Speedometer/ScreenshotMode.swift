import Foundation

/// App Store 用のスクリーンショットを撮るための起動モード。
///
/// 起動引数に `-screenshots` を付けると、広告と ATT の確認を出さない。
/// 広告が写り込んだスクリーンショットは App Store の審査で問題になるうえ、
/// 許可ダイアログが被ると撮影自体ができないため。
enum ScreenshotMode {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshots")
    }
}
