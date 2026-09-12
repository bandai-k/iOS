import Foundation

/// 追加できるタイムゾーンの選択肢 1 つ分。
public struct OffsetOption: Identifiable, Hashable, Sendable {
    /// UTC からのずれ (分)。`Identifiable` の ID も兼ねる。
    public let minutes: Int
    /// `UTC+05:45` のような表記。
    public let label: String
    /// そのずれで暮らしている代表的な都市名。
    public let regions: [String]

    public var id: Int { minutes }

    /// 補足に出す 1 行。例: `Kathmandu`、`Tokyo, Seoul ほか`
    public var regionSummary: String {
        OffsetCatalog.summary(of: regions)
    }

    public init(minutes: Int, label: String, regions: [String]) {
        self.minutes = minutes
        self.label = label
        self.regions = regions
    }
}

/// 端末が知っているタイムゾーンから「UTC からのずれ」の一覧を作るところ。
///
/// 400 件以上ある地域名をそのまま並べると選びにくいので、このアプリでは
/// ずれ (`UTC+09:00` など) を選択肢にし、代表的な都市名を補足として添える。
public enum OffsetCatalog {
    /// `UTC+05:45` / `UTC-03:30` のような表記を作る。
    public static func label(forMinutes minutes: Int) -> String {
        let sign = minutes < 0 ? "-" : "+"
        let absolute = abs(minutes)
        return String(format: "UTC%@%02d:%02d", sign, absolute / 60, absolute % 60)
    }

    /// その時点で実際に使われているずれの一覧を、小さい順に返す。
    ///
    /// 夏時間の分だけ季節でずれる地域があるので、基準の日時を渡せるようにしている。
    public static func options(at date: Date = Date()) -> [OffsetOption] {
        var regionsByMinutes: [Int: [String]] = [:]

        for identifier in TimeZone.knownTimeZoneIdentifiers {
            guard let timeZone = TimeZone(identifier: identifier) else { continue }
            let minutes = timeZone.secondsFromGMT(for: date) / 60
            if let city = cityName(from: identifier) {
                regionsByMinutes[minutes, default: []].append(city)
            } else {
                // `GMT` のように地域名を持たない識別子。ずれ自体は選択肢に出したいので空で登録する。
                regionsByMinutes[minutes] = regionsByMinutes[minutes] ?? []
            }
        }

        return regionsByMinutes
            .map { minutes, regions in
                OffsetOption(
                    minutes: minutes,
                    label: label(forMinutes: minutes),
                    regions: regions.sorted()
                )
            }
            .sorted { $0.minutes < $1.minutes }
    }

    /// そのずれの代表的な都市名をまとめた 1 行。
    public static func regionSummary(forMinutes minutes: Int, at date: Date = Date()) -> String {
        let option = options(at: date).first { $0.minutes == minutes }
        return summary(of: option?.regions ?? [])
    }

    static func summary(of regions: [String]) -> String {
        switch regions.count {
        case 0: return "UTC からの固定のずれ"
        case 1: return regions[0]
        case 2: return regions.joined(separator: ", ")
        default: return "\(regions[0]), \(regions[1]) ほか"
        }
    }

    /// `Asia/Tokyo` → `Tokyo`、`America/Argentina/Buenos_Aires` → `Buenos Aires`。
    private static func cityName(from identifier: String) -> String? {
        let parts = identifier.split(separator: "/")
        guard parts.count >= 2, let last = parts.last else { return nil }
        return last.replacingOccurrences(of: "_", with: " ")
    }
}
