import Foundation

/// 野菜と回数の組ごとのベストタイム。
public struct ChopRecord: Codable, Equatable, Sendable {
    public let vegetable: Vegetable
    public let cutCount: Int
    public let seconds: TimeInterval
    public let achievedAt: Date

    public init(vegetable: Vegetable, cutCount: Int, seconds: TimeInterval, achievedAt: Date) {
        self.vegetable = vegetable
        self.cutCount = cutCount
        self.seconds = seconds
        self.achievedAt = achievedAt
    }

    /// 保存用のキー。回数が違えば別の記録として扱う。
    public var key: String { "\(vegetable.rawValue)-\(cutCount)" }

    /// 1 カットあたりの秒数。
    public var secondsPerCut: TimeInterval {
        cutCount > 0 ? seconds / Double(cutCount) : 0
    }
}

/// タイムの表示形式。小数第 2 位まで。
public enum ChopTimeFormatter {
    public static func string(_ seconds: TimeInterval) -> String {
        String(format: "%.2f", max(seconds, 0))
    }
}
