import XCTest
@testable import SiteRecordCore

final class SiteBoardTests: XCTestCase {
    func testRowsSkipEmptyFields() {
        let board = SiteBoard(projectName: "〇〇橋下部工事", workType: "配筋", location: "A1 橋台")
        XCTAssertEqual(board.rows.map(\.label), ["工事名", "工種", "施工箇所"])
        XCTAssertEqual(board.rows.map(\.value), ["〇〇橋下部工事", "配筋", "A1 橋台"])
    }

    func testEmptyBoard() {
        XCTAssertTrue(SiteBoard.empty.isEmpty)
        XCTAssertFalse(SiteBoard(workType: "掘削").isEmpty)
    }

    func testTrimmedDropsSurroundingWhitespace() {
        let board = SiteBoard(projectName: "  〇〇工事 \n", note: "   ")
        let trimmed = board.trimmed()
        XCTAssertEqual(trimmed.projectName, "〇〇工事")
        XCTAssertEqual(trimmed.note, "")
        XCTAssertEqual(trimmed.rows.count, 1)
    }
}

final class BoardTimestampTests: XCTestCase {
    func testFormatsInFixed24HourStyle() {
        let jst = BoardTimestamp(timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        // 2024-01-02T03:04:05Z = JST 12:04:05
        let date = Date(timeIntervalSince1970: 1_704_164_645)
        XCTAssertEqual(jst.string(for: date), "2024/01/02 12:04:05")
    }

    func testUsesGivenTimeZone() {
        let utc = BoardTimestamp(timeZone: TimeZone(identifier: "UTC")!)
        let date = Date(timeIntervalSince1970: 1_704_164_645)
        XCTAssertEqual(utc.string(for: date), "2024/01/02 03:04:05")
    }
}

final class SiteBoardStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "SiteBoardStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testLoadReturnsEmptyBoardWhenNothingSaved() {
        XCTAssertEqual(SiteBoardStore(defaults: defaults).load(), .empty)
    }

    func testRoundTrip() {
        let store = SiteBoardStore(defaults: defaults)
        let board = SiteBoard(projectName: "〇〇道路改良工事", workType: "舗装", location: "No.12+5")
        store.save(board)
        XCTAssertEqual(store.load(), board)
    }

    func testSaveTrimsBeforePersisting() {
        let store = SiteBoardStore(defaults: defaults)
        store.save(SiteBoard(projectName: "  〇〇工事  "))
        XCTAssertEqual(store.load().projectName, "〇〇工事")
    }

    func testCorruptedDataFallsBackToEmptyBoard() {
        defaults.set(Data("not json".utf8), forKey: SiteBoardStore.defaultKey)
        XCTAssertEqual(SiteBoardStore(defaults: defaults).load(), .empty)
    }
}
