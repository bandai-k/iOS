import Foundation

/// 1 回の千切りゲームの状態。
///
/// 時計は最初のタップで動き出し、目標回数に届いたタップで止まる。
/// 時刻は呼び出し側から渡すので、テストで実時間を待つ必要がない。
public struct ChopSession: Equatable, Sendable {
    public let vegetable: Vegetable
    public let target: Int

    public private(set) var cutCount: Int = 0
    public private(set) var startedAt: Date?
    public private(set) var finishedAt: Date?

    public init(vegetable: Vegetable, target: Int) {
        self.vegetable = vegetable
        self.target = ChopRules.clamp(target)
    }

    public var isRunning: Bool { startedAt != nil && finishedAt == nil }
    public var isFinished: Bool { finishedAt != nil }
    public var hasStarted: Bool { startedAt != nil }

    /// 0.0 〜 1.0。
    public var progress: Double {
        guard target > 0 else { return 1 }
        return min(Double(cutCount) / Double(target), 1)
    }

    public var remaining: Int { max(target - cutCount, 0) }

    /// 1 タップ＝ 1 カット。最初のタップが計測開始、目標到達のタップが計測終了。
    /// 終了後のタップは無視する。
    public mutating func cut(at date: Date) {
        guard !isFinished else { return }
        if startedAt == nil {
            startedAt = date
        }
        cutCount += 1
        if cutCount >= target {
            finishedAt = date
        }
    }

    /// 経過秒。開始前は 0、終了後は確定タイムで止まる。
    public func elapsed(at date: Date) -> TimeInterval {
        guard let startedAt else { return 0 }
        let end = finishedAt ?? date
        return max(end.timeIntervalSince(startedAt), 0)
    }

    /// 終了していれば確定タイム。
    public var result: TimeInterval? {
        guard let startedAt, let finishedAt else { return nil }
        return max(finishedAt.timeIntervalSince(startedAt), 0)
    }
}
