import Foundation

/// 画面に並べるタイムゾーンの一覧を端末に保存しておく入れ物。
///
/// 追加・削除の結果は次回起動時も残ってほしいので `UserDefaults` に JSON で置く。
public final class ClockZoneListStore {
    public static let defaultKey = "clock_zones"

    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = ClockZoneListStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    /// 保存済みの一覧。未保存や壊れている場合は既定 (UTC / JST) を返す。
    public func load() -> [ClockZone] {
        guard
            let data = defaults.data(forKey: key),
            let zones = try? JSONDecoder().decode([ClockZone].self, from: data),
            !zones.isEmpty
        else {
            return ClockZone.defaults
        }
        return ClockZoneList.normalized(zones)
    }

    public func save(_ zones: [ClockZone]) {
        guard let data = try? JSONEncoder().encode(ClockZoneList.normalized(zones)) else { return }
        defaults.set(data, forKey: key)
    }
}

/// 一覧そのものの決まりごと (重複を許さない / UTC は残す / ずれ順に並べる)。
public enum ClockZoneList {
    /// 追加する。すでに同じゾーンがある場合は何もしない。
    public static func adding(_ zone: ClockZone, to zones: [ClockZone]) -> [ClockZone] {
        guard !zones.contains(where: { $0.id == zone.id }) else { return zones }
        return normalized(zones + [zone])
    }

    /// 削除する。UTC は変換の基準なので消せない。最後の 1 つも残す。
    public static func removing(_ zone: ClockZone, from zones: [ClockZone]) -> [ClockZone] {
        guard zone.isRemovable, zones.count > 1 else { return zones }
        return zones.filter { $0.id != zone.id }
    }

    /// 重複を取り除き、UTC からのずれが小さい順に並べる。
    public static func normalized(_ zones: [ClockZone], at date: Date = Date()) -> [ClockZone] {
        var seen: Set<String> = []
        let unique = zones.filter { seen.insert($0.id).inserted }
        return unique.sorted { left, right in
            let leftOffset = left.timeZone.secondsFromGMT(for: date)
            let rightOffset = right.timeZone.secondsFromGMT(for: date)
            if leftOffset != rightOffset { return leftOffset < rightOffset }
            return left.id < right.id
        }
    }
}
