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
        XCTAssertEqual(ClockZone.all.map(\.id), ["UTC", "JST"])
        XCTAssertEqual(ClockZone.jst.timeZone.identifier, "Asia/Tokyo")
    }
}
