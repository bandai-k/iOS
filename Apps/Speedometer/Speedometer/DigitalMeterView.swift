import SpeedometerCore
import SwiftUI

/// デジタル表示のメーター。数字を大きく出すだけの画面。
struct DigitalMeterView: View {
    let speed: Double?
    let scale: GaugeScale
    let unit: SpeedUnit

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            VStack(spacing: size * 0.04) {
                Text(speed.map { String(Int($0.rounded())) } ?? "--")
                    .font(.system(size: size * 0.46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .foregroundStyle(speed == nil ? Color.secondary : Color.primary)

                Text(unit.symbol)
                    .font(.system(size: size * 0.1, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                bar(width: size * 0.8)
                    .padding(.top, size * 0.04)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(speed == nil ? "速度を測定中" : "\(Int(speed!.rounded())) \(unit.symbol)")
    }

    /// 目盛りの中でいまどのあたりかを示す帯。アナログ側の弧と同じ役割。
    private func bar(width: CGFloat) -> some View {
        let ratio = scale.clamped(speed ?? 0) / scale.maximum

        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.primary.opacity(0.08))
            Capsule()
                .fill(Color.accentColor.opacity(speed == nil ? 0.15 : 0.85))
                .frame(width: width * ratio)
                .animation(.easeOut(duration: 0.35), value: ratio)
        }
        .frame(width: width, height: 10)
    }
}

#Preview {
    VStack {
        DigitalMeterView(speed: 82, scale: .road, unit: .kilometersPerHour)
        DigitalMeterView(speed: nil, scale: .road, unit: .kilometersPerHour)
    }
    .padding()
}
