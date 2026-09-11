import Foundation

/// アプリで表示するタイムゾーン 1 つ分の定義。
///
/// 表示用の文言と `TimeZone` をまとめて持つので、画面側はレイアウトだけに集中できる。
public struct ClockZone: Identifiable, Hashable, Sendable {
    /// 画面に大きく出す短縮名 (例: `UTC`)。`Identifiable` の ID も兼ねる。
    public let id: String
    /// 日本語の正式名称 (例: `協定世界時`)。
    public let name: String
    /// IANA タイムゾーン識別子 (例: `Asia/Tokyo`)。
    public let timeZoneIdentifier: String

    public init(id: String, name: String, timeZoneIdentifier: String) {
        self.id = id
        self.name = name
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    /// 識別子から解決した `TimeZone`。解決できない場合は GMT にフォールバックする。
    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? TimeZone(secondsFromGMT: 0)!
    }

    public static let utc = ClockZone(
        id: "UTC",
        name: "協定世界時",
        timeZoneIdentifier: "UTC"
    )

    public static let jst = ClockZone(
        id: "JST",
        name: "日本標準時",
        timeZoneIdentifier: "Asia/Tokyo"
    )

    /// このアプリが表示する順番のタイムゾーン一覧。
    public static let all: [ClockZone] = [.utc, .jst]
}
