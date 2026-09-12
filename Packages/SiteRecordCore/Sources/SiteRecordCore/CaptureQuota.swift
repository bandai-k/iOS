import Foundation

/// 無料で撮れる残り枚数の管理。
///
/// 1 日 2 枚までは無料で、日付が変わればまた 2 枚撮れる。
/// 判定に使う「今日」は端末のカレンダー基準なので、時計を外から渡せるようにしてある。
public struct CaptureQuota: Equatable, Codable, Sendable {
    /// 1 日に無料で撮れる枚数。
    public static let freeDailyLimit = 2

    /// 数え始めた日 (その日の 0 時)。
    public var day: Date
    /// その日に撮った枚数。
    public var count: Int

    public init(day: Date, count: Int) {
        self.day = day
        self.count = count
    }

    /// まだ 1 枚も撮っていない状態。
    public static func empty(at date: Date, calendar: Calendar = .current) -> CaptureQuota {
        CaptureQuota(day: calendar.startOfDay(for: date), count: 0)
    }

    /// 日付が変わっていれば数え直した写し。
    public func refreshed(at date: Date, calendar: Calendar = .current) -> CaptureQuota {
        let today = calendar.startOfDay(for: date)
        guard today != day else { return self }
        return CaptureQuota(day: today, count: 0)
    }

    /// 1 枚撮ったあとの写し。
    public func recording(at date: Date, calendar: Calendar = .current) -> CaptureQuota {
        var next = refreshed(at: date, calendar: calendar)
        next.count += 1
        return next
    }

    /// その日にあと何枚無料で撮れるか。
    public func remaining(at date: Date, calendar: Calendar = .current) -> Int {
        max(Self.freeDailyLimit - refreshed(at: date, calendar: calendar).count, 0)
    }

    /// 無料のまま撮れるか。買い切り版を持っている場合は呼ぶ必要がない。
    public func allowsCapture(at date: Date, calendar: Calendar = .current) -> Bool {
        remaining(at: date, calendar: calendar) > 0
    }
}

/// 残り枚数を端末に保存しておく入れ物。
public final class CaptureQuotaStore {
    public static let defaultKey = "capture_quota"

    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = CaptureQuotaStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    /// 保存済みの枚数。未保存や壊れている場合は「今日まだ 0 枚」を返す。
    public func load(at date: Date = Date(), calendar: Calendar = .current) -> CaptureQuota {
        guard
            let data = defaults.data(forKey: key),
            let quota = try? JSONDecoder().decode(CaptureQuota.self, from: data)
        else {
            return .empty(at: date, calendar: calendar)
        }
        return quota.refreshed(at: date, calendar: calendar)
    }

    public func save(_ quota: CaptureQuota) {
        guard let data = try? JSONEncoder().encode(quota) else { return }
        defaults.set(data, forKey: key)
    }
}
