import AppTrackingTransparency
import GoogleMobileAds
import UIKit

/// 広告まわりの起動処理。
enum Ads {
    /// トラッキングの確認を出してから広告 SDK を始める。
    ///
    /// 断られても広告自体は出る（IDFA を使わない配信になる）ので、結果に関わらず SDK は開始する。
    @MainActor
    static func start() async {
        await requestTrackingIfNeeded()
        await MobileAds.shared.start()
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
}
