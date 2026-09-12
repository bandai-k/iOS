import Foundation

/// アナログメーターの目盛りの決め方。
///
/// 針の角度も目盛りの位置もここで計算するので、画面側は描画だけを担当する。
public struct GaugeScale: Equatable, Sendable {
    /// 目盛りの上限 (単位はメーターが表示している単位)。
    public let maximum: Double
    /// 数字を書く目盛りの間隔。
    public let majorStep: Double
    /// 数字を書かない細い目盛りの間隔。
    public let minorStep: Double

    /// 0 の位置 (度)。画面の真上を 0 度、時計回りを正とする。
    public let startDegrees: Double
    /// 0 から最大値までの開き (度)。
    public let sweepDegrees: Double

    public init(
        maximum: Double,
        majorStep: Double,
        minorStep: Double,
        startDegrees: Double = -135,
        sweepDegrees: Double = 270
    ) {
        self.maximum = maximum
        self.majorStep = majorStep
        self.minorStep = minorStep
        self.startDegrees = startDegrees
        self.sweepDegrees = sweepDegrees
    }

    /// 一般道・高速道路向け。
    public static let road = GaugeScale(maximum: 180, majorStep: 20, minorStep: 10)
    /// 新幹線・特急向け。
    public static let rail = GaugeScale(maximum: 360, majorStep: 40, minorStep: 20)

    /// 速度が増えたときに切り替えていく順番。
    public static let presets: [GaugeScale] = [.road, .rail]

    /// 目盛りの範囲に収めた速度。
    public func clamped(_ speed: Double) -> Double {
        min(max(speed, 0), maximum)
    }

    /// その速度を指すときの針の角度 (度)。範囲外の速度は端で止める。
    public func degrees(for speed: Double) -> Double {
        startDegrees + sweepDegrees * (clamped(speed) / maximum)
    }

    /// 数字を書く目盛りの値。
    public var majorTicks: [Double] {
        stride(from: 0, through: maximum, by: majorStep).map { $0 }
    }

    /// 細い目盛りの値 (数字を書くものは除く)。
    public var minorTicks: [Double] {
        stride(from: 0, through: maximum, by: minorStep)
            .filter { $0.truncatingRemainder(dividingBy: majorStep) != 0 }
            .map { $0 }
    }
}

/// 速度に合わせて目盛りの上限を切り替えるところ。
///
/// 上限のすぐ手前で行ったり来たりすると針が落ち着かないので、
/// 上げるのは早め (8 割)、下げるのは遅め (5 割を下回ってから) にしている。
public enum GaugeScaleSelector {
    public static let increaseRatio = 0.8
    public static let decreaseRatio = 0.5

    /// いまの目盛りと速度から、次に使う目盛りを返す。
    public static func scale(for speed: Double, current: GaugeScale) -> GaugeScale {
        let presets = GaugeScale.presets
        guard let index = presets.firstIndex(of: current) else { return presets[0] }

        if speed > current.maximum * increaseRatio, index + 1 < presets.count {
            return presets[index + 1]
        }
        if index > 0, speed < presets[index - 1].maximum * decreaseRatio {
            return presets[index - 1]
        }
        return current
    }
}
