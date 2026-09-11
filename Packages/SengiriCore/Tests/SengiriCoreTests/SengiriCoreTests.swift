import XCTest
@testable import SengiriCore

final class ChopSessionTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    func testClockStartsOnFirstCut() {
        var session = ChopSession(vegetable: .cabbage, target: 3)
        XCTAssertFalse(session.hasStarted)
        XCTAssertEqual(session.elapsed(at: start.addingTimeInterval(5)), 0)

        session.cut(at: start)
        XCTAssertTrue(session.isRunning)
        XCTAssertEqual(session.cutCount, 1)
        XCTAssertEqual(session.elapsed(at: start.addingTimeInterval(2)), 2)
    }

    func testFinishesAtTargetAndFreezesTime() {
        var session = ChopSession(vegetable: .cucumber, target: 3)
        session.cut(at: start)
        session.cut(at: start.addingTimeInterval(0.5))
        XCTAssertFalse(session.isFinished)

        session.cut(at: start.addingTimeInterval(1.25))
        XCTAssertTrue(session.isFinished)
        XCTAssertEqual(session.result ?? -1, 1.25, accuracy: 0.0001)
        // 終了後は時間が進まない。
        XCTAssertEqual(session.elapsed(at: start.addingTimeInterval(99)), 1.25, accuracy: 0.0001)
    }

    func testCutsAfterFinishAreIgnored() {
        var session = ChopSession(vegetable: .carrot, target: 2)
        session.cut(at: start)
        session.cut(at: start.addingTimeInterval(1))
        session.cut(at: start.addingTimeInterval(2))
        XCTAssertEqual(session.cutCount, 2)
        XCTAssertEqual(session.result ?? -1, 1, accuracy: 0.0001)
    }

    func testProgressAndRemaining() {
        var session = ChopSession(vegetable: .cabbage, target: 4)
        XCTAssertEqual(session.progress, 0)
        XCTAssertEqual(session.remaining, 4)
        session.cut(at: start)
        session.cut(at: start)
        XCTAssertEqual(session.progress, 0.5)
        XCTAssertEqual(session.remaining, 2)
    }

    func testTargetIsClampedToRules() {
        XCTAssertEqual(ChopSession(vegetable: .cabbage, target: 1).target, ChopRules.cutCountRange.lowerBound)
        XCTAssertEqual(ChopSession(vegetable: .cabbage, target: 9_999).target, ChopRules.cutCountRange.upperBound)
    }
}

final class ChopTimeFormatterTests: XCTestCase {
    func testFormatsTwoDecimals() {
        XCTAssertEqual(ChopTimeFormatter.string(1.234), "1.23")
        XCTAssertEqual(ChopTimeFormatter.string(12.006), "12.01")
        XCTAssertEqual(ChopTimeFormatter.string(0), "0.00")
    }

    func testNegativeTimesAreClampedToZero() {
        XCTAssertEqual(ChopTimeFormatter.string(-3), "0.00")
    }
}

final class ChopStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private let now = Date(timeIntervalSince1970: 1_000_000)

    override func setUp() {
        super.setUp()
        suiteName = "ChopStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testCutCountFallsBackToVegetableDefault() {
        let store = ChopSettingsStore(defaults: defaults)
        XCTAssertEqual(store.cutCount(for: .cabbage), Vegetable.cabbage.defaultCutCount)
    }

    func testCutCountRoundTripAndClamping() {
        let store = ChopSettingsStore(defaults: defaults)
        store.setCutCount(80, for: .carrot)
        XCTAssertEqual(store.cutCount(for: .carrot), 80)
        // 他の野菜には影響しない。
        XCTAssertEqual(store.cutCount(for: .cabbage), Vegetable.cabbage.defaultCutCount)

        store.setCutCount(1_000, for: .carrot)
        XCTAssertEqual(store.cutCount(for: .carrot), ChopRules.cutCountRange.upperBound)
    }

    func testOnlyFasterRecordsAreKept() {
        let store = ChopRecordStore(defaults: defaults)
        let first = ChopRecord(vegetable: .cabbage, cutCount: 50, seconds: 20, achievedAt: now)
        XCTAssertTrue(store.submit(first))
        XCTAssertEqual(store.best(for: .cabbage, cutCount: 50), first)

        let slower = ChopRecord(vegetable: .cabbage, cutCount: 50, seconds: 25, achievedAt: now)
        XCTAssertFalse(store.submit(slower))
        XCTAssertEqual(store.best(for: .cabbage, cutCount: 50)?.seconds, 20)

        let faster = ChopRecord(vegetable: .cabbage, cutCount: 50, seconds: 18.5, achievedAt: now)
        XCTAssertTrue(store.submit(faster))
        XCTAssertEqual(store.best(for: .cabbage, cutCount: 50)?.seconds, 18.5)
    }

    func testRecordsAreSeparatedByCutCount() {
        let store = ChopRecordStore(defaults: defaults)
        store.submit(ChopRecord(vegetable: .cucumber, cutCount: 30, seconds: 10, achievedAt: now))
        XCTAssertNotNil(store.best(for: .cucumber, cutCount: 30))
        XCTAssertNil(store.best(for: .cucumber, cutCount: 40))
        XCTAssertNil(store.best(for: .carrot, cutCount: 30))
    }

    func testResetClearsRecords() {
        let store = ChopRecordStore(defaults: defaults)
        store.submit(ChopRecord(vegetable: .carrot, cutCount: 40, seconds: 12, achievedAt: now))
        store.reset()
        XCTAssertNil(store.best(for: .carrot, cutCount: 40))
    }

    func testSecondsPerCut() {
        let record = ChopRecord(vegetable: .cabbage, cutCount: 50, seconds: 25, achievedAt: now)
        XCTAssertEqual(record.secondsPerCut, 0.5, accuracy: 0.0001)
    }
}
