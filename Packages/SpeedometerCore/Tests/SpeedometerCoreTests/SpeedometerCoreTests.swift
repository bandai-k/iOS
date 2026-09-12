import XCTest
@testable import SpeedometerCore

final class SpeedUnitTests: XCTestCase {
    func testKilometersPerHourConversion() {
        XCTAssertEqual(SpeedUnit.kilometersPerHour.value(fromMetersPerSecond: 10), 36, accuracy: 0.0001)
        XCTAssertEqual(SpeedUnit.kilometersPerHour.value(fromMetersPerSecond: 0), 0)
    }

    func testMilesPerHourConversion() {
        // 時速 100km ≒ 62.14mph
        let mph = SpeedUnit.milesPerHour.value(fromMetersPerSecond: 100 / 3.6)
        XCTAssertEqual(mph, 62.137, accuracy: 0.001)
    }

    func testSymbols() {
        XCTAssertEqual(SpeedUnit.kilometersPerHour.symbol, "km/h")
        XCTAssertEqual(SpeedUnit.milesPerHour.symbol, "mph")
    }
}

final class SpeedReadingTests: XCTestCase {
    func testNegativeSpeedIsUnavailable() {
        // CoreLocation は速度が取れないとき -1 を返す。
        XCTAssertFalse(SpeedReading.fromLocation(metersPerSecond: -1).isAvailable)
        XCTAssertNil(SpeedReading.fromLocation(metersPerSecond: -1).value(in: .kilometersPerHour))
        XCTAssertEqual(SpeedReading.fromLocation(metersPerSecond: -1).text(in: .kilometersPerHour), "--")
    }

    func testStoppedIsAvailable() {
        // 停車中の 0 は「測れていない」ではなく 0km/h として扱う。
        let stopped = SpeedReading.fromLocation(metersPerSecond: 0)
        XCTAssertTrue(stopped.isAvailable)
        XCTAssertEqual(stopped.text(in: .kilometersPerHour), "0")
    }

    func testTextRounds() {
        let reading = SpeedReading.fromLocation(metersPerSecond: 27.7)  // 99.7km/h
        XCTAssertEqual(reading.text(in: .kilometersPerHour), "100")
    }

    func testNonFiniteIsUnavailable() {
        XCTAssertFalse(SpeedReading.fromLocation(metersPerSecond: .nan).isAvailable)
        XCTAssertFalse(SpeedReading.fromLocation(metersPerSecond: .infinity).isAvailable)
    }
}

final class GaugeScaleTests: XCTestCase {
    func testNeedleAnglesSpanTheScale() {
        let scale = GaugeScale.road
        XCTAssertEqual(scale.degrees(for: 0), -135, accuracy: 0.0001)
        XCTAssertEqual(scale.degrees(for: 90), 0, accuracy: 0.0001, "中間は真上を向く")
        XCTAssertEqual(scale.degrees(for: 180), 135, accuracy: 0.0001)
    }

    func testSpeedsOutsideTheScaleStopAtTheEnd() {
        let scale = GaugeScale.road
        XCTAssertEqual(scale.degrees(for: 500), 135, accuracy: 0.0001)
        XCTAssertEqual(scale.degrees(for: -20), -135, accuracy: 0.0001)
        XCTAssertEqual(scale.clamped(500), 180)
        XCTAssertEqual(scale.clamped(-20), 0)
    }

    func testTicks() {
        let scale = GaugeScale.road
        XCTAssertEqual(scale.majorTicks, [0, 20, 40, 60, 80, 100, 120, 140, 160, 180])
        XCTAssertEqual(scale.minorTicks, [10, 30, 50, 70, 90, 110, 130, 150, 170])
        // 数字付きと細い目盛りは重ならない。
        XCTAssertTrue(Set(scale.majorTicks).isDisjoint(with: Set(scale.minorTicks)))
    }

    func testRailScaleReachesShinkansenSpeeds() {
        XCTAssertEqual(GaugeScale.rail.maximum, 360)
        XCTAssertEqual(GaugeScale.rail.clamped(320), 320)
    }
}

final class GaugeScaleSelectorTests: XCTestCase {
    func testSwitchesUpNearTheTopOfTheScale() {
        // 180 の 8 割 = 144 を超えたら新幹線向けの目盛りへ。
        XCTAssertEqual(GaugeScaleSelector.scale(for: 140, current: .road), .road)
        XCTAssertEqual(GaugeScaleSelector.scale(for: 150, current: .road), .rail)
    }

    func testStaysUntilSpeedDropsWellBelow() {
        // 上げた直後に戻らないよう、戻すのは 180 の 5 割 = 90 を下回ってから。
        XCTAssertEqual(GaugeScaleSelector.scale(for: 140, current: .rail), .rail)
        XCTAssertEqual(GaugeScaleSelector.scale(for: 100, current: .rail), .rail)
        XCTAssertEqual(GaugeScaleSelector.scale(for: 80, current: .rail), .road)
    }

    func testDoesNotGoBeyondThePresets() {
        XCTAssertEqual(GaugeScaleSelector.scale(for: 1000, current: .rail), .rail)
        XCTAssertEqual(GaugeScaleSelector.scale(for: 0, current: .road), .road)
    }
}

final class SpeedFreshnessTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    func testNoUpdateYetIsStale() {
        XCTAssertTrue(SpeedFreshness.isStale(lastUpdate: nil, now: now))
    }

    func testRecentUpdateIsFresh() {
        XCTAssertFalse(SpeedFreshness.isStale(lastUpdate: now.addingTimeInterval(-1), now: now))
        XCTAssertFalse(SpeedFreshness.isStale(lastUpdate: now.addingTimeInterval(-5), now: now))
    }

    func testOldUpdateIsStale() {
        // トンネルで位置情報が途切れた場合を想定。
        XCTAssertTrue(SpeedFreshness.isStale(lastUpdate: now.addingTimeInterval(-6), now: now))
        XCTAssertTrue(SpeedFreshness.isStale(lastUpdate: now.addingTimeInterval(-60), now: now))
    }
}
