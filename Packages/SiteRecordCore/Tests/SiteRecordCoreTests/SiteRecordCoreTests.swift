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
