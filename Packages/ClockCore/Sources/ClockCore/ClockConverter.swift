import Foundation

/// 「カレンダー上の見た目の日時」と「実際の瞬間 (`Date`)」を行き来させるための変換。
///
/// 画面の `DatePicker` は端末のタイムゾーンで日時を読み書きするため、
/// 「UTC の 2024-01-02 12:00」のように別ゾーンの壁時計時刻を入力させたいときは、
/// ここで一度ゾーンを付け替える必要がある。
public enum ClockConverter {
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    /// `date` をそのゾーンで見たときの年月日時分秒を取り出す。
    public static func wallClock(of date: Date, in timeZone: TimeZone) -> DateComponents {
        var calendar = calendar
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }

    /// 年月日時分秒をそのゾーンの壁時計時刻とみなして `Date` を組み立てる。
    ///
    /// 夏時間の切り替えで存在しない時刻を渡した場合は `Calendar` が近い時刻へ寄せる。
    public static func date(fromWallClock components: DateComponents, in timeZone: TimeZone) -> Date? {
        var calendar = calendar
        calendar.timeZone = timeZone
        var components = components
        components.timeZone = timeZone
        return calendar.date(from: components)
    }

    /// 見た目の日時 (年月日時分秒) を保ったまま、別のタイムゾーンの時刻として読み替える。
    ///
    /// 例: 端末が JST のとき `2024-01-02 12:00` を指す `Date` を `to: UTC` で読み替えると、
    /// 「UTC の 2024-01-02 12:00」= JST の 21:00 を指す `Date` になる。
    public static func reinterpret(_ date: Date, from source: TimeZone, to destination: TimeZone) -> Date {
        let components = wallClock(of: date, in: source)
        return self.date(fromWallClock: components, in: destination) ?? date
    }
}

public extension ClockConverter {
    /// 秒を切り捨てて分ちょうどに揃える。
    ///
    /// 画面の `DatePicker` は分までしか入力できないので、変換結果に中途半端な秒が
    /// 残らないように入力値をここで丸めておく。
    static func alignedToMinute(_ date: Date) -> Date {
        let seconds = date.timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: (seconds / 60).rounded(.down) * 60)
    }
}
