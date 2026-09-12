import Foundation

/// 速度の単位。位置情報から来る値は m/s なので、表示用に換算する。
public enum SpeedUnit: String, CaseIterable, Identifiable, Sendable {
    case kilometersPerHour
    case milesPerHour

    public var id: String { rawValue }

    /// メーターに出す単位表記。
    public var symbol: String {
        switch self {
        case .kilometersPerHour: return "km/h"
        case .milesPerHour: return "mph"
        }
    }

    /// m/s からこの単位の値へ換算する。
    public func value(fromMetersPerSecond metersPerSecond: Double) -> Double {
        switch self {
        case .kilometersPerHour: return metersPerSecond * 3.6
        case .milesPerHour: return metersPerSecond * 2.236_936_292_054_402
        }
    }
}
