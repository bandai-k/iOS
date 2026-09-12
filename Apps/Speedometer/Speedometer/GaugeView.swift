import SpeedometerCore
import SwiftUI

/// アナログのスピードメーター本体。
///
/// 目盛りの値と角度は `GaugeScale` が持っているので、ここは描くだけ。
struct GaugeView: View {
    let speed: Double?
    let scale: GaugeScale
    let unit: SpeedUnit

    /// 針が指す速度。測れていないときは 0 の位置で止める。
    private var needleSpeed: Double { speed ?? 0 }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2

            ZStack {
                dial(radius: radius)
                ticks(radius: radius)
                needle(radius: radius)
                hub
                readout(radius: radius)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// 文字盤の弧。0 から最大値までの帯を薄く敷く。
    private func dial(radius: CGFloat) -> some View {
        let trim = scale.sweepDegrees / 360

        return ZStack {
            Circle()
                .trim(from: 0, to: trim)
                .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: radius * 0.16, lineCap: .round))
            Circle()
                .trim(from: 0, to: trim * (scale.clamped(needleSpeed) / scale.maximum))
                .stroke(
                    Color.accentColor.opacity(speed == nil ? 0.15 : 0.85),
                    style: StrokeStyle(lineWidth: radius * 0.16, lineCap: .round)
                )
        }
        // Circle の trim は右 (3 時) から始まるので、0 の位置まで回してから描く。
        .rotationEffect(.degrees(scale.startDegrees - 90))
        .padding(radius * 0.1)
    }

    private func ticks(radius: CGFloat) -> some View {
        ZStack {
            ForEach(scale.minorTicks, id: \.self) { value in
                tick(at: value, radius: radius, length: radius * 0.06, width: 1.5, opacity: 0.35)
            }
            ForEach(scale.majorTicks, id: \.self) { value in
                tick(at: value, radius: radius, length: radius * 0.11, width: 3, opacity: 0.7)
                label(for: value, radius: radius)
            }
        }
    }

    private func tick(at value: Double, radius: CGFloat, length: CGFloat, width: CGFloat, opacity: Double) -> some View {
        Rectangle()
            .fill(Color.primary.opacity(opacity))
            .frame(width: width, height: length)
            .offset(y: -(radius - radius * 0.3))
            .rotationEffect(.degrees(scale.degrees(for: value)))
    }

    private func label(for value: Double, radius: CGFloat) -> some View {
        let angle = Angle.degrees(scale.degrees(for: value) - 90)
        let distance = radius * 0.57

        return Text(String(Int(value)))
            .font(.system(size: radius * 0.12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .position(
                x: radius + cos(angle.radians) * distance,
                y: radius + sin(angle.radians) * distance
            )
            .frame(width: radius * 2, height: radius * 2)
    }

    private func needle(radius: CGFloat) -> some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: radius * 0.035, height: radius * 0.72)
            .offset(y: -radius * 0.26)
            .rotationEffect(.degrees(scale.degrees(for: needleSpeed)))
            .opacity(speed == nil ? 0.25 : 1)
            // 実際の速度は細かく揺れるので、針の動きは少し滑らかにする。
            .animation(.easeOut(duration: 0.35), value: needleSpeed)
            .animation(.easeInOut(duration: 0.4), value: scale)
    }

    private var hub: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: 14, height: 14)
    }

    /// メーター中央の数字。目盛りの数字と重ならないよう、大きさも位置も半径から決める。
    private func readout(radius: CGFloat) -> some View {
        VStack(spacing: radius * 0.02) {
            Text(speed.map { String(Int($0.rounded())) } ?? "--")
                .font(.system(size: radius * 0.34, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text(unit.symbol)
                .font(.system(size: radius * 0.11, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .offset(y: radius * 0.3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(speed == nil ? "速度を測定中" : "\(Int(speed!.rounded())) \(unit.symbol)")
    }
}

#Preview {
    VStack {
        GaugeView(speed: 82, scale: .road, unit: .kilometersPerHour)
        GaugeView(speed: nil, scale: .road, unit: .kilometersPerHour)
    }
    .padding()
}
