import Foundation

/// 位置情報から受け取った速度 1 回分。
///
/// `CoreLocation` は速度が取れていないとき負の値を返すので、
/// 「測れていない」状態をここで一度はっきりさせてから画面に渡す。
public struct SpeedReading: Equatable, Sendable {
    /// 秒速 (m/s)。測れていない場合は `nil`。
    public let metersPerSecond: Double?

    public init(metersPerSecond: Double?) {
        self.metersPerSecond = metersPerSecond
    }

    /// 測れていない状態。
    public static let unavailable = SpeedReading(metersPerSecond: nil)

    /// `CoreLocation` の値から作る。負の値は「測れていない」として扱う。
    public static func fromLocation(metersPerSecond: Double) -> SpeedReading {
        guard metersPerSecond >= 0, metersPerSecond.isFinite else { return .unavailable }
        return SpeedReading(metersPerSecond: metersPerSecond)
    }

    public var isAvailable: Bool { metersPerSecond != nil }

    /// 指定の単位での値。測れていない場合は `nil`。
    public func value(in unit: SpeedUnit) -> Double? {
        metersPerSecond.map { unit.value(fromMetersPerSecond: $0) }
    }

    /// メーター中央に出す数字。測れていないときは `--`。
    public func text(in unit: SpeedUnit) -> String {
        guard let value = value(in: unit) else { return "--" }
        return String(Int(value.rounded()))
    }
}
