import Foundation

/// ある瞬間の時刻を、そのまま画面に流し込める文字列にしたもの。
public struct ClockSnapshot: Equatable, Sendable {
    /// `HH:mm:ss` 形式の時刻。
    public let time: String
    /// `yyyy-MM-dd (EEE)` 形式の日付。
    public let date: String
    /// `UTC+09:00` 形式の UTC からのオフセット。
    public let offset: String

    public init(time: String, date: String, offset: String) {
        self.time = time
        self.date = date
        self.offset = offset
    }
}
