import BannerAds
import SpeedometerCore
import SwiftUI

/// 表示の種類。左右のスワイプで切り替える。
enum MeterStyle: String, CaseIterable, Identifiable {
    case analog
    case digital

    var id: String { rawValue }
}

/// いまの速度を見せるだけの画面。アナログとデジタルをスワイプで行き来する。
struct SpeedometerScreen: View {
    @StateObject private var provider = SpeedProvider()
    @State private var scale: GaugeScale = .road
    /// 最後に見ていた表示を次回起動時も出したいので端末に保存する。
    @AppStorage("meterStyle") private var meterStyleRaw: String = MeterStyle.analog.rawValue

    private let unit: SpeedUnit = .kilometersPerHour

    private var speed: Double? {
        provider.reading.value(in: unit)
    }

    /// `TabView` から読み書きするための入れ物。保存済みの文字列と行き来させる。
    private var meterStyle: Binding<MeterStyle> {
        Binding(
            get: { MeterStyle(rawValue: meterStyleRaw) ?? .analog },
            set: { meterStyleRaw = $0.rawValue }
        )
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                TabView(selection: meterStyle) {
                    GaugeView(speed: speed, scale: scale, unit: unit)
                        .padding(.horizontal, 24)
                        .tag(MeterStyle.analog)

                    DigitalMeterView(speed: speed, scale: scale, unit: unit)
                        .padding(.horizontal, 24)
                        .tag(MeterStyle.digital)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                status

                AdBannerSlot(unitID: AdUnits.banner)
            }
            .padding(.top, 24)
            .padding(.bottom, 8)
        }
        .onAppear {
            provider.start()
            // 走行中に画面が消えると意味がないので、表示中はスリープさせない。
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            provider.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: speed ?? 0) { _, newSpeed in
            // 新幹線の速度域に入ったら目盛りを広げ、落ち着いたら戻す。
            let next = GaugeScaleSelector.scale(for: newSpeed, current: scale)
            if next != scale { scale = next }
        }
    }

    @ViewBuilder
    private var status: some View {
        if provider.isDenied {
            message("位置情報の利用が許可されていません。設定アプリから許可すると速度が表示されます。")
        } else if speed == nil {
            message("速度を測定中です。空が見える場所で、少し移動すると表示されます。")
        } else {
            Text("最大 \(Int(scale.maximum)) \(unit.symbol) の目盛り")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
    }
}

#Preview {
    SpeedometerScreen()
}
