import XCTest
@testable import ClockCore

final class ClockCoreTests: XCTestCase {
    /// 2024-01-02T03:04:05Z
    private let reference = Date(timeIntervalSince1970: 1_704_164_645)

    func testUTCSnapshot() {
        let snapshot = ClockFormatter(zone: .utc).snapshot(at: reference)
        XCTAssertEqual(snapshot.time, "03:04:05")
        XCTAssertEqual(snapshot.date, "2024-01-02 (Tue)")
        XCTAssertEqual(snapshot.offset, "UTC+00:00")
    }

    func testJSTSnapshotIsNineHoursAhead() {
        let snapshot = ClockFormatter(zone: .jst).snapshot(at: reference)
        XCTAssertEqual(snapshot.time, "12:04:05")
        XCTAssertEqual(snapshot.date, "2024-01-02 (Tue)")
        XCTAssertEqual(snapshot.offset, "UTC+09:00")
    }

    func testJSTCrossesToNextDayBeforeUTC() {
        // 2024-01-02T16:00:00Z は JST では翌日の 01:00。
        let evening = Date(timeIntervalSince1970: 1_704_211_200)
        let jst = ClockFormatter(zone: .jst).snapshot(at: evening)
        XCTAssertEqual(jst.time, "01:00:00")
        XCTAssertEqual(jst.date, "2024-01-03 (Wed)")
    }

    func testNegativeOffsetFormatting() {
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        XCTAssertEqual(ClockFormatter.offsetText(for: losAngeles, at: reference), "UTC-08:00")
    }

    func testZonesResolve() {
        XCTAssertEqual(ClockZone.defaults.map(\.id), ["UTC", "JST"])
        XCTAssertEqual(ClockZone.jst.timeZone.identifier, "Asia/Tokyo")
    }
}

final class HourStyleTests: XCTestCase {
    /// 2024-01-02T03:04:05Z (JST では 12:04:05)
    private let reference = Date(timeIntervalSince1970: 1_704_164_645)

    func testTwelveHourAfternoonShowsPM() {
        let snapshot = ClockFormatter(zone: .jst, hourStyle: .twelve).snapshot(at: reference)
        XCTAssertEqual(snapshot.time, "12:04:05 PM")
    }

    func testTwelveHourMorningShowsAM() {
        let snapshot = ClockFormatter(zone: .utc, hourStyle: .twelve).snapshot(at: reference)
        XCTAssertEqual(snapshot.time, "3:04:05 AM")
    }

    func testMidnightIsTwelveAM() {
        // 2024-01-02T15:00:00Z は JST で翌日 00:00。
        let midnightJST = Date(timeIntervalSince1970: 1_704_207_600)
        let snapshot = ClockFormatter(zone: .jst, hourStyle: .twelve).snapshot(at: midnightJST)
        XCTAssertEqual(snapshot.time, "12:00:00 AM")
        XCTAssertEqual(snapshot.date, "2024-01-03 (Wed)")
    }

    func testTwentyFourHourIsDefault() {
        XCTAssertEqual(ClockFormatter(zone: .jst).hourStyle, .twentyFour)
        XCTAssertEqual(ClockFormatter(zone: .jst).snapshot(at: reference).time, "12:04:05")
    }
}

final class ClockConverterTests: XCTestCase {
    private let utc = TimeZone(identifier: "UTC")!
    private let jst = TimeZone(identifier: "Asia/Tokyo")!

    func testWallClockRoundTrip() {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 2
        components.hour = 12
        components.minute = 0
        components.second = 0

        let date = ClockConverter.date(fromWallClock: components, in: jst)
        XCTAssertNotNil(date)
        // JST の 12:00 は UTC の 03:00。
        XCTAssertEqual(ClockFormatter(zone: .utc).snapshot(at: date!).time, "03:00:00")

        let readBack = ClockConverter.wallClock(of: date!, in: jst)
        XCTAssertEqual(readBack.hour, 12)
        XCTAssertEqual(readBack.day, 2)
    }

    func testReinterpretKeepsWallClockAndShiftsInstant() {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 2
        components.hour = 12
        let asJST = ClockConverter.date(fromWallClock: components, in: jst)!

        // 「JST の 12:00」を「UTC の 12:00」として読み替えると 9 時間後の瞬間になる。
        let asUTC = ClockConverter.reinterpret(asJST, from: jst, to: utc)
        XCTAssertEqual(asUTC.timeIntervalSince(asJST), 9 * 3600)
        XCTAssertEqual(ClockFormatter(zone: .utc).snapshot(at: asUTC).time, "12:00:00")
        XCTAssertEqual(ClockFormatter(zone: .jst).snapshot(at: asUTC).time, "21:00:00")
    }

    func testReinterpretIsIdentityForSameZone() {
        let now = Date(timeIntervalSince1970: 1_704_164_645)
        // 秒より細かい端数は壁時計時刻に含まれないので、秒単位で比べる。
        let truncated = Date(timeIntervalSince1970: 1_704_164_645)
        XCTAssertEqual(ClockConverter.reinterpret(now, from: jst, to: jst), truncated)
    }
}

final class MinuteAlignmentTests: XCTestCase {
    func testAlignedToMinuteDropsSeconds() {
        // 2024-01-02T03:04:05Z
        let date = Date(timeIntervalSince1970: 1_704_164_645)
        let aligned = ClockConverter.alignedToMinute(date)
        XCTAssertEqual(ClockFormatter(zone: .utc).snapshot(at: aligned).time, "03:04:00")
    }

    func testAlignedToMinuteIsStable() {
        let date = Date(timeIntervalSince1970: 1_704_164_640)
        XCTAssertEqual(ClockConverter.alignedToMinute(date), date)
    }
}

final class OffsetCatalogTests: XCTestCase {
    func testLabelFormatting() {
        XCTAssertEqual(OffsetCatalog.label(forMinutes: 0), "UTC+00:00")
        XCTAssertEqual(OffsetCatalog.label(forMinutes: 9 * 60), "UTC+09:00")
        XCTAssertEqual(OffsetCatalog.label(forMinutes: 345), "UTC+05:45")
        XCTAssertEqual(OffsetCatalog.label(forMinutes: -210), "UTC-03:30")
    }

    func testOptionsCoverKnownOffsets() {
        let options = OffsetCatalog.options()
        // 端末が知っているゾーンから作るので、主要なずれは必ず含まれる。
        let minutes = Set(options.map(\.minutes))
        XCTAssertTrue(minutes.contains(0))
        XCTAssertTrue(minutes.contains(9 * 60))
        XCTAssertTrue(minutes.contains(345), "ネパールの UTC+05:45 が落ちている")
        // 小さい順に並んでいる。
        XCTAssertEqual(options.map(\.minutes), options.map(\.minutes).sorted())
        // ずれは重複しない。
        XCTAssertEqual(minutes.count, options.count)
    }

    func testOptionCarriesRegionNames() {
        let jst = OffsetCatalog.options().first { $0.minutes == 9 * 60 }
        XCTAssertNotNil(jst)
        XCTAssertTrue(jst!.regions.contains("Tokyo"))
        XCTAssertFalse(jst!.regionSummary.isEmpty)
    }

    func testSummaryShortens() {
        XCTAssertEqual(OffsetCatalog.summary(of: []), "UTC からの固定のずれ")
        XCTAssertEqual(OffsetCatalog.summary(of: ["Kathmandu"]), "Kathmandu")
        XCTAssertEqual(OffsetCatalog.summary(of: ["Tokyo", "Seoul"]), "Tokyo, Seoul")
        XCTAssertEqual(OffsetCatalog.summary(of: ["Tokyo", "Seoul", "Palau"]), "Tokyo, Seoul ほか")
    }
}

final class ClockZoneListTests: XCTestCase {
    private let kathmandu = ClockZone.fixedOffset(minutes: 345, name: "Kathmandu")
    private let losAngeles = ClockZone.fixedOffset(minutes: -8 * 60, name: "Los Angeles")

    func testFixedOffsetZoneFormatsTime() {
        // 2024-01-02T03:04:05Z は UTC+05:45 では 08:49:05。
        let reference = Date(timeIntervalSince1970: 1_704_164_645)
        XCTAssertEqual(kathmandu.id, "UTC+05:45")
        let snapshot = ClockFormatter(zone: kathmandu).snapshot(at: reference)
        XCTAssertEqual(snapshot.time, "08:49:05")
        XCTAssertEqual(snapshot.offset, "UTC+05:45")
    }

    func testAddingAndRemoving() {
        var zones = ClockZone.defaults
        zones = ClockZoneList.adding(kathmandu, to: zones)
        XCTAssertEqual(zones.map(\.id), ["UTC", "UTC+05:45", "JST"], "ずれの小さい順に並ぶ")

        // 同じゾーンは二重に入らない。
        zones = ClockZoneList.adding(kathmandu, to: zones)
        XCTAssertEqual(zones.count, 3)

        zones = ClockZoneList.removing(kathmandu, from: zones)
        XCTAssertEqual(zones.map(\.id), ["UTC", "JST"])
    }

    func testUTCCannotBeRemoved() {
        let zones = ClockZoneList.removing(.utc, from: ClockZone.defaults)
        XCTAssertEqual(zones.map(\.id), ["UTC", "JST"])
        XCTAssertFalse(ClockZone.utc.isRemovable)
        XCTAssertTrue(ClockZone.jst.isRemovable)
    }

    func testLastZoneIsKept() {
        let zones = ClockZoneList.removing(.jst, from: [.jst])
        XCTAssertEqual(zones.map(\.id), ["JST"])
    }

    func testNegativeOffsetSortsFirst() {
        let zones = ClockZoneList.normalized([.jst, .utc, losAngeles])
        XCTAssertEqual(zones.map(\.id), ["UTC-08:00", "UTC", "JST"])
    }

    func testStoreRoundTrip() {
        let defaults = UserDefaults(suiteName: "ClockZoneListTests")!
        defaults.removePersistentDomain(forName: "ClockZoneListTests")
        let store = ClockZoneListStore(defaults: defaults, key: "zones")

        XCTAssertEqual(store.load().map(\.id), ["UTC", "JST"], "未保存なら既定が出る")

        store.save(ClockZoneList.adding(kathmandu, to: ClockZone.defaults))
        let loaded = store.load()
        XCTAssertEqual(loaded.map(\.id), ["UTC", "UTC+05:45", "JST"])
        // 固定ずれのゾーンも復元できている。
        XCTAssertEqual(loaded[1].timeZone.secondsFromGMT(), 345 * 60)
    }

    func testBrokenDataFallsBackToDefaults() {
        let defaults = UserDefaults(suiteName: "ClockZoneListTests")!
        defaults.set(Data("not json".utf8), forKey: "zones")
        XCTAssertEqual(ClockZoneListStore(defaults: defaults, key: "zones").load().map(\.id), ["UTC", "JST"])
        defaults.removePersistentDomain(forName: "ClockZoneListTests")
    }
}
