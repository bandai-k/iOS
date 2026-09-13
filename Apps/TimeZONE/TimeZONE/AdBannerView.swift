import GoogleMobileAds
import SwiftUI
import UIKit

/// 画面下に出す広告バナー。
///
/// 広告 SDK は UIKit のビューしか用意していないので、SwiftUI から使えるように包む。
struct AdBannerView: UIViewRepresentable {
    /// このアプリ用に AdMob で作ったバナーの広告ユニット ID。
    static let unitID = "ca-app-pub-6037710903474110/4690918964"

    /// 広告の中身を出さずに動作だけ見たいときのための、Google が公開しているテスト用 ID。
    static let testUnitID = "ca-app-pub-3940256099942544/2934735716"

    let unitID: String

    init(unitID: String = AdBannerView.unitID) {
        self.unitID = unitID
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = unitID
        banner.rootViewController = Self.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    /// 広告のタップ後に開く画面を載せるための、いま表示されている画面。
    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

/// バナーの定位置。高さを固定しておき、読み込み前でも画面が動かないようにする。
struct AdBannerSlot: View {
    var body: some View {
        if ScreenshotMode.isActive {
            // 撮影中は枠ごと出さない。
            EmptyView()
        } else {
            AdBannerView()
                .frame(height: 50)
                .frame(maxWidth: .infinity)
        }
    }
}
