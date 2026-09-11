import Foundation

/// 看板の内容を端末に保存しておくための入れ物。
///
/// 起動直後にカメラを出したいので、読み込みは同期で済む `UserDefaults` に置く。
public final class SiteBoardStore {
    public static let defaultKey = "site_board"

    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = SiteBoardStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    /// 保存済みの看板。未保存や壊れている場合は空の看板を返す。
    public func load() -> SiteBoard {
        guard let data = defaults.data(forKey: key) else { return .empty }
        return (try? JSONDecoder().decode(SiteBoard.self, from: data)) ?? .empty
    }

    public func save(_ board: SiteBoard) {
        guard let data = try? JSONEncoder().encode(board.trimmed()) else { return }
        defaults.set(data, forKey: key)
    }
}
