import Foundation

/// アプリで表示するタイムゾーン 1 つ分の定義。
///
/// 表示用の文言と `TimeZone` をまとめて持つので、画面側はレイアウトだけに集中できる。
public struct ClockZone: Identifiable, Hashable, Codable, Sendable {
    /// このゾーンの実体。地域名で持つか、UTC からのずれで持つか。
    public enum Kind: Hashable, Codable, Sendable {
        /// IANA タイムゾーン識別子 (例: `Asia/Tokyo`)。夏時間があるゾーンは季節でずれが変わる。
        case region(identifier: String)
        /// UTC からの固定のずれ (分単位)。夏時間は考慮しない。
        case fixedOffset(minutes: Int)
    }

    /// 画面に大きく出す短縮名 (例: `UTC`、`UTC+05:45`)。`Identifiable` の ID も兼ねる。
    public let id: String
    /// 補足の名前 (例: `協定世界時`、`Kathmandu など`)。
    public let name: String
    public let kind: Kind

    public init(id: String, name: String, kind: Kind) {
        self.id = id
        self.name = name
        self.kind = kind
    }

    /// 解決した `TimeZone`。解決できない場合は GMT にフォールバックする。
    public var timeZone: TimeZone {
        switch kind {
        case let .region(identifier):
            return TimeZone(identifier: identifier) ?? TimeZone(secondsFromGMT: 0)!
        case let .fixedOffset(minutes):
            return TimeZone(secondsFromGMT: minutes * 60) ?? TimeZone(secondsFromGMT: 0)!
        }
    }

    /// 消せない既定のゾーンかどうか。UTC は変換の基準なので常に残す。
    public var isRemovable: Bool { self != .utc }

    public static let utc = ClockZone(
        id: "UTC",
        name: "協定世界時",
        kind: .region(identifier: "UTC")
    )

    public static let jst = ClockZone(
        id: "JST",
        name: "日本標準時",
        kind: .region(identifier: "Asia/Tokyo")
    )

    /// 追加も削除もされていない初期状態のゾーン一覧。
    public static let defaults: [ClockZone] = [.utc, .jst]

    /// UTC からのずれ (分) から、`UTC+05:45` のようなゾーンを作る。
    ///
    /// - Parameter name: 補足に出す文言。省略すると代表的な地域名が入る。
    public static func fixedOffset(minutes: Int, name: String? = nil) -> ClockZone {
        ClockZone(
            id: OffsetCatalog.label(forMinutes: minutes),
            name: name ?? OffsetCatalog.regionSummary(forMinutes: minutes),
            kind: .fixedOffset(minutes: minutes)
        )
    }
}
