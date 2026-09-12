import Foundation

/// 1 つのタイムゾーン + 表記スタイル用に `DateFormatter` を組み立てて使い回すフォーマッタ。
///
/// `DateFormatter` の生成はそれなりに重いので、組み合わせごとに 1 度だけ作って
/// 毎秒の更新では `snapshot(at:)` を呼ぶだけにしている。
public struct ClockFormatter {
    public let zone: ClockZone
    public let hourStyle: HourStyle

    private let timeFormatter: DateFormatter
    private let dateFormatter: DateFormatter

    public init(zone: ClockZone, hourStyle: HourStyle = .twentyFour) {
        self.zone = zone
        self.hourStyle = hourStyle

        let timeZone = zone.timeZone
        // 端末のロケール設定に左右されず書式を固定するため en_US_POSIX を使う。
        // (AM / PM 表記も端末の言語によらず常に "AM" / "PM" になる)
        let locale = Locale(identifier: "en_US_POSIX")

        timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.timeZone = timeZone
        timeFormatter.dateFormat = hourStyle.timeFormat

        dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd (EEE)"
    }

    public func snapshot(at date: Date) -> ClockSnapshot {
        ClockSnapshot(
            time: timeFormatter.string(from: date),
            date: dateFormatter.string(from: date),
            offset: Self.offsetText(for: zone.timeZone, at: date)
        )
    }

    /// `UTC+09:00` のような表記を組み立てる。夏時間があるゾーンでも日時に応じて正しく出る。
    public static func offsetText(for timeZone: TimeZone, at date: Date) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds < 0 ? "-" : "+"
        let absolute = abs(seconds)
        let hours = absolute / 3600
        let minutes = (absolute % 3600) / 60
        return String(format: "UTC%@%02d:%02d", sign, hours, minutes)
    }
}

/// ゾーン × 表記スタイルごとの `ClockFormatter` を 1 つだけ作って共有するキャッシュ。
///
/// SwiftUI の View は更新のたびに再生成されるため、View の中で `ClockFormatter` を
/// 作ると毎回 `DateFormatter` の初期化が走ってしまう。ここに逃がして使い回す。
@MainActor
public enum ClockFormatterStore {
    private static var formatters: [String: ClockFormatter] = [:]

    public static func formatter(for zone: ClockZone, hourStyle: HourStyle = .twentyFour) -> ClockFormatter {
        let key = "\(zone.id)|\(hourStyle.rawValue)"
        if let cached = formatters[key] {
            return cached
        }
        let created = ClockFormatter(zone: zone, hourStyle: hourStyle)
        formatters[key] = created
        return created
    }
}
