import AppTrackingTransparency
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// 広告まわりの起動処理。
///
/// 手順は Google の案内どおり、同意フォーム → ATT の確認 → 広告 SDK の開始。
/// 同意フォームは AdMob の管理画面で作ったメッセージを出すもので、
/// EEA など必要な地域でだけ表示される。
enum Ads {
    @MainActor
    static func start() async {
        // スクリーンショット撮影中は広告も確認ダイアログも出さない。
        guard !ScreenshotMode.isActive else { return }

        await gatherConsent()
        await requestTrackingIfNeeded()

        // 同意が得られていない状態では広告を要求しない。
        guard ConsentInformation.shared.canRequestAds else { return }
        await MobileAds.shared.start()
    }

    /// 同意の状態を取り直し、必要ならフォームを出す。
    @MainActor
    private static func gatherConsent() async {
        let parameters = RequestParameters()
        // 子ども向けではないので、その旨は指定しない（既定のまま）。

        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            try await ConsentForm.loadAndPresentIfRequired(from: rootViewController)
        } catch {
            // フォームが出せなくても、広告を出せる状態なら続行する。
        }
    }

    /// まだ確認していなければ ATT の確認を出す。
    ///
    /// 起動直後はアプリがまだ前面に出ておらず、その状態で頼むと確認が出ないまま
    /// 「未決定」で返ってくる。前面になるまで少し待ってから頼む。
    @MainActor
    private static func requestTrackingIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        for _ in 0..<30 where UIApplication.shared.applicationState != .active {
            try? await Task.sleep(for: .milliseconds(100))
        }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    /// 同意フォームを載せる画面。
    @MainActor
    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
