import Foundation

/// 野菜ごとの千切り回数の設定を覚えておく。
public final class ChopSettingsStore {
    public static let defaultKey = "chop_cut_counts"

    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = ChopSettingsStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    public func cutCount(for vegetable: Vegetable) -> Int {
        guard let stored = counts()[vegetable.rawValue] else { return vegetable.defaultCutCount }
        return ChopRules.clamp(stored)
    }

    public func setCutCount(_ count: Int, for vegetable: Vegetable) {
        var current = counts()
        current[vegetable.rawValue] = ChopRules.clamp(count)
        guard let data = try? JSONEncoder().encode(current) else { return }
        defaults.set(data, forKey: key)
    }

    private func counts() -> [String: Int] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return decoded
    }
}

/// ベストタイムを保存する。速い方だけ残す。
public final class ChopRecordStore {
    public static let defaultKey = "chop_records"

    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = ChopRecordStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    public func best(for vegetable: Vegetable, cutCount: Int) -> ChopRecord? {
        records()["\(vegetable.rawValue)-\(cutCount)"]
    }

    /// 記録を出す。これまでより速ければ保存して `true` を返す。
    @discardableResult
    public func submit(_ record: ChopRecord) -> Bool {
        var current = records()
        if let existing = current[record.key], existing.seconds <= record.seconds {
            return false
        }
        current[record.key] = record
        guard let data = try? JSONEncoder().encode(current) else { return false }
        defaults.set(data, forKey: key)
        return true
    }

    public func reset() {
        defaults.removeObject(forKey: key)
    }

    private func records() -> [String: ChopRecord] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: ChopRecord].self, from: data) else {
            return [:]
        }
        return decoded
    }
}
