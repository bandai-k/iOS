import Foundation

/// 時刻を 24 時間表記で出すか、AM / PM 付きの 12 時間表記で出すか。
public enum HourStyle: String, CaseIterable, Identifiable, Sendable {
    /// `15:04:05`
    case twentyFour
    /// `3:04:05 PM`
    case twelve

    public var id: String { rawValue }

    /// 設定画面などに出す短い名前。
    public var label: String {
        switch self {
        case .twentyFour: return "24 時間"
        case .twelve: return "AM / PM"
        }
    }

    /// `DateFormatter.dateFormat` に渡す書式。
    ///
    /// ロケールに依存しない固定書式なので、フォーマッタ側は必ず `en_US_POSIX` と組で使う。
    var timeFormat: String {
        switch self {
        case .twentyFour: return "HH:mm:ss"
        case .twelve: return "h:mm:ss a"
        }
    }
}
