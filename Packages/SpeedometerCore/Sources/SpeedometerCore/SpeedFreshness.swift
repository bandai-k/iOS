import Foundation

/// 受け取った速度がまだ信用できるかを判断するところ。
///
/// トンネルなどで位置情報が途切れると更新が止まるだけなので、
/// 一定時間来なくなったら「測れていない」に戻さないと古い速度が出たままになる。
public enum SpeedFreshness {
    /// これだけ更新が来なければ古いとみなす秒数。
    public static let maxAge: TimeInterval = 5

    public static func isStale(lastUpdate: Date?, now: Date = Date(), maxAge: TimeInterval = maxAge) -> Bool {
        guard let lastUpdate else { return true }
        return now.timeIntervalSince(lastUpdate) > maxAge
    }
}
