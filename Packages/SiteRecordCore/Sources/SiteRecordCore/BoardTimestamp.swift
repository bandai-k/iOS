import Foundation

/// 写真に焼き込む撮影日時の文字列を作る。
///
/// 記録写真は後から日時で突き合わせるので、端末のロケール設定に関わらず
/// 常に `yyyy/MM/dd HH:mm:ss`（24 時間表記）で出す。
public struct BoardTimestamp {
    private let formatter: DateFormatter

    public init(timeZone: TimeZone = .current) {
        formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
    }

    public func string(for date: Date) -> String {
        formatter.string(from: date)
    }
}
