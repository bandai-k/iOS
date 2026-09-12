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

final class PhotoMetadataTests: XCTestCase {
    private let exifKey = kCGImagePropertyExifDictionary as String
    private let tiffKey = kCGImagePropertyTIFFDictionary as String

    /// 横向きに撮った 4032x3024 の写真から来たメタデータ、という想定。
    private var captured: [String: Any] {
        [
            kCGImagePropertyPixelWidth as String: 4032,
            kCGImagePropertyPixelHeight as String: 3024,
            kCGImagePropertyOrientation as String: 6,
            exifKey: [
                kCGImagePropertyExifDateTimeOriginal as String: "2026:09:12 09:41:07",
                kCGImagePropertyExifPixelXDimension as String: 4032,
                kCGImagePropertyExifPixelYDimension as String: 3024,
                kCGImagePropertyExifLensModel as String: "iPhone 17 back camera"
            ],
            tiffKey: [
                kCGImagePropertyTIFFMake as String: "Apple",
                kCGImagePropertyTIFFModel as String: "iPhone 17",
                kCGImagePropertyTIFFOrientation as String: 6
            ]
        ]
    }

    func testCaptureInformationIsKept() {
        let result = PhotoMetadata.forComposite(original: captured, pixelSize: CGSize(width: 3024, height: 4032))
        let exif = result[exifKey] as? [String: Any]
        let tiff = result[tiffKey] as? [String: Any]

        XCTAssertEqual(exif?[kCGImagePropertyExifDateTimeOriginal as String] as? String, "2026:09:12 09:41:07")
        XCTAssertEqual(exif?[kCGImagePropertyExifLensModel as String] as? String, "iPhone 17 back camera")
        XCTAssertEqual(tiff?[kCGImagePropertyTIFFMake as String] as? String, "Apple")
        XCTAssertEqual(tiff?[kCGImagePropertyTIFFModel as String] as? String, "iPhone 17")
    }

    func testOrientationIsNormalized() {
        // 合成では上向きに描き直すので、元の向き (6 = 90 度回転) を引き継いではいけない。
        let result = PhotoMetadata.forComposite(original: captured, pixelSize: CGSize(width: 3024, height: 4032))
        XCTAssertEqual(result[kCGImagePropertyOrientation as String] as? Int, 1)
        XCTAssertEqual((result[tiffKey] as? [String: Any])?[kCGImagePropertyTIFFOrientation as String] as? Int, 1)
    }

    func testPixelSizeMatchesTheComposedImage() {
        let result = PhotoMetadata.forComposite(original: captured, pixelSize: CGSize(width: 3024, height: 4032))
        let exif = result[exifKey] as? [String: Any]

        XCTAssertEqual(result[kCGImagePropertyPixelWidth as String] as? Int, 3024)
        XCTAssertEqual(result[kCGImagePropertyPixelHeight as String] as? Int, 4032)
        XCTAssertEqual(exif?[kCGImagePropertyExifPixelXDimension as String] as? Int, 3024)
        XCTAssertEqual(exif?[kCGImagePropertyExifPixelYDimension as String] as? Int, 4032)
    }

    func testSoftwareIsRecorded() {
        let result = PhotoMetadata.forComposite(
            original: captured,
            pixelSize: CGSize(width: 100, height: 100),
            software: "SiteRecord"
        )
        XCTAssertEqual((result[tiffKey] as? [String: Any])?[kCGImagePropertyTIFFSoftware as String] as? String, "SiteRecord")
    }

    func testEmptyMetadataStillGetsSizeAndOrientation() {
        let result = PhotoMetadata.forComposite(original: [:], pixelSize: CGSize(width: 640, height: 480))
        XCTAssertEqual(result[kCGImagePropertyOrientation as String] as? Int, 1)
        XCTAssertEqual((result[exifKey] as? [String: Any])?[kCGImagePropertyExifPixelXDimension as String] as? Int, 640)
    }

    func testStaleThumbnailIsDropped() {
        var original = captured
        original[kCGImagePropertyThumbnailImages as String] = ["stale"]
        let result = PhotoMetadata.forComposite(original: original, pixelSize: CGSize(width: 100, height: 100))
        XCTAssertNil(result[kCGImagePropertyThumbnailImages as String])
    }
}

final class GPSMetadataTests: XCTestCase {
    /// 2026-09-12T09:41:07Z
    private let timestamp = Date(timeIntervalSince1970: 1_789_206_067)

    private func gps(latitude: Double, longitude: Double, altitude: Double? = nil, accuracy: Double? = nil) -> [String: Any]? {
        GPSMetadata.dictionary(for: PhotoLocation(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            horizontalAccuracy: accuracy,
            timestamp: timestamp
        ))
    }

    func testNorthEastCoordinates() {
        // 東京駅あたり。
        let result = gps(latitude: 35.681236, longitude: 139.767125)
        XCTAssertEqual(result?[kCGImagePropertyGPSLatitude as String] as? Double, 35.681236)
        XCTAssertEqual(result?[kCGImagePropertyGPSLatitudeRef as String] as? String, "N")
        XCTAssertEqual(result?[kCGImagePropertyGPSLongitude as String] as? Double, 139.767125)
        XCTAssertEqual(result?[kCGImagePropertyGPSLongitudeRef as String] as? String, "E")
    }

    func testSouthWestCoordinatesAreStoredAsAbsoluteValues() {
        // EXIF は符号ではなく方角の記号で持つ。
        let result = gps(latitude: -33.8688, longitude: -70.6693)
        XCTAssertEqual(result?[kCGImagePropertyGPSLatitude as String] as? Double, 33.8688)
        XCTAssertEqual(result?[kCGImagePropertyGPSLatitudeRef as String] as? String, "S")
        XCTAssertEqual(result?[kCGImagePropertyGPSLongitude as String] as? Double, 70.6693)
        XCTAssertEqual(result?[kCGImagePropertyGPSLongitudeRef as String] as? String, "W")
    }

    func testTimeStampIsUTC() {
        // 端末が JST でも GPS の時刻は UTC で書く。
        let result = gps(latitude: 35.681236, longitude: 139.767125)
        XCTAssertEqual(result?[kCGImagePropertyGPSTimeStamp as String] as? String, "09:41:07")
        XCTAssertEqual(result?[kCGImagePropertyGPSDateStamp as String] as? String, "2026:09:12")
    }

    func testAltitudeReference() {
        let above = gps(latitude: 35.6, longitude: 139.7, altitude: 40.5)
        XCTAssertEqual(above?[kCGImagePropertyGPSAltitude as String] as? Double, 40.5)
        XCTAssertEqual(above?[kCGImagePropertyGPSAltitudeRef as String] as? Int, 0)

        let below = gps(latitude: 35.6, longitude: 139.7, altitude: -12)
        XCTAssertEqual(below?[kCGImagePropertyGPSAltitude as String] as? Double, 12, "海面下も絶対値で持つ")
        XCTAssertEqual(below?[kCGImagePropertyGPSAltitudeRef as String] as? Int, 1)
    }

    func testAccuracyIsOptional() {
        let withAccuracy = gps(latitude: 35.6, longitude: 139.7, accuracy: 8)
        XCTAssertEqual(withAccuracy?[kCGImagePropertyGPSHPositioningError as String] as? Double, 8)

        // CoreLocation は測れていないとき負の誤差を返す。
        let invalid = gps(latitude: 35.6, longitude: 139.7, accuracy: -1)
        XCTAssertNil(invalid?[kCGImagePropertyGPSHPositioningError as String])
    }

    func testUnmeasuredLocationIsRejected() {
        XCTAssertNil(gps(latitude: 0, longitude: 0), "0,0 は測位できていない値として扱う")
        XCTAssertNil(gps(latitude: .nan, longitude: 139.7))
        XCTAssertNil(gps(latitude: 91, longitude: 139.7))
        XCTAssertNil(gps(latitude: 35.6, longitude: 181))
    }

    func testCompositeMetadataCarriesLocation() {
        let metadata = PhotoMetadata.forComposite(
            original: [:],
            pixelSize: CGSize(width: 100, height: 100),
            location: PhotoLocation(latitude: 35.681236, longitude: 139.767125, timestamp: timestamp)
        )
        let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any]
        XCTAssertEqual(gps?[kCGImagePropertyGPSLatitudeRef as String] as? String, "N")
    }

    func testCompositeMetadataWithoutLocationHasNoGPS() {
        let metadata = PhotoMetadata.forComposite(original: [:], pixelSize: CGSize(width: 100, height: 100))
        XCTAssertNil(metadata[kCGImagePropertyGPSDictionary as String])
    }
}

final class CaptureQuotaTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()

    /// 2026-09-12 09:00 JST
    private let morning = Date(timeIntervalSince1970: 1_789_171_200)

    private func quota() -> CaptureQuota { .empty(at: morning, calendar: calendar) }

    func testThreeFreeCapturesPerDay() {
        var quota = quota()
        XCTAssertEqual(quota.remaining(at: morning, calendar: calendar), 3)

        for expected in [2, 1, 0] {
            XCTAssertTrue(quota.allowsCapture(at: morning, calendar: calendar))
            quota = quota.recording(at: morning, calendar: calendar)
            XCTAssertEqual(quota.remaining(at: morning, calendar: calendar), expected)
        }
        XCTAssertFalse(quota.allowsCapture(at: morning, calendar: calendar), "4 枚目は無料では撮れない")
    }

    func testCountResetsNextDay() {
        var quota = quota()
        for _ in 0..<3 { quota = quota.recording(at: morning, calendar: calendar) }
        XCTAssertFalse(quota.allowsCapture(at: morning, calendar: calendar))

        // 同じ日の深夜 23:59 はまだ数え直さない。
        let lateNight = morning.addingTimeInterval(14 * 3600 + 59 * 60)
        XCTAssertEqual(quota.remaining(at: lateNight, calendar: calendar), 0)

        // 日付が変わればまた 3 枚。
        let nextDay = morning.addingTimeInterval(24 * 3600)
        XCTAssertEqual(quota.remaining(at: nextDay, calendar: calendar), 3)
        XCTAssertTrue(quota.allowsCapture(at: nextDay, calendar: calendar))
    }

    func testRecordingAfterMidnightStartsFromOne() {
        var quota = quota()
        for _ in 0..<3 { quota = quota.recording(at: morning, calendar: calendar) }

        let nextDay = morning.addingTimeInterval(24 * 3600)
        quota = quota.recording(at: nextDay, calendar: calendar)
        XCTAssertEqual(quota.count, 1)
        XCTAssertEqual(quota.remaining(at: nextDay, calendar: calendar), 2)
    }

    func testStoreRoundTripAndDailyReset() {
        let defaults = UserDefaults(suiteName: "CaptureQuotaTests")!
        defaults.removePersistentDomain(forName: "CaptureQuotaTests")
        let store = CaptureQuotaStore(defaults: defaults, key: "quota")

        XCTAssertEqual(store.load(at: morning, calendar: calendar).count, 0, "未保存なら 0 枚")

        store.save(quota().recording(at: morning, calendar: calendar))
        XCTAssertEqual(store.load(at: morning, calendar: calendar).count, 1)

        // 日をまたいだら保存済みの値に関係なく 0 枚から。
        let nextDay = morning.addingTimeInterval(24 * 3600)
        XCTAssertEqual(store.load(at: nextDay, calendar: calendar).count, 0)

        defaults.removePersistentDomain(forName: "CaptureQuotaTests")
    }

    func testBrokenDataFallsBackToEmpty() {
        let defaults = UserDefaults(suiteName: "CaptureQuotaTests")!
        defaults.set(Data("not json".utf8), forKey: "quota")
        let store = CaptureQuotaStore(defaults: defaults, key: "quota")
        XCTAssertEqual(store.load(at: morning, calendar: calendar).count, 0)
        defaults.removePersistentDomain(forName: "CaptureQuotaTests")
    }
}
