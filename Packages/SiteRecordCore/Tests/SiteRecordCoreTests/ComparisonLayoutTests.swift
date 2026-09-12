import CoreGraphics
import XCTest
@testable import SiteRecordCore

final class ComparisonLayoutTests: XCTestCase {
    private let square = CGSize(width: 1000, height: 1000)

    // 1000x1000 が 2 枚 → labelHeight 60 / padding 20 / gap 20
    func testHorizontalLayoutOfIdenticalImages() {
        let layout = ComparisonComposer.layout(beforeSize: square, afterSize: square, axis: .horizontal)
        XCTAssertEqual(layout.canvasSize, CGSize(width: 2060, height: 1100))
        XCTAssertEqual(layout.slots.count, 2)
        XCTAssertEqual(layout.slots[0].labelRect, CGRect(x: 20, y: 20, width: 1000, height: 60))
        XCTAssertEqual(layout.slots[0].imageRect, CGRect(x: 20, y: 80, width: 1000, height: 1000))
        XCTAssertEqual(layout.slots[1].labelRect, CGRect(x: 1040, y: 20, width: 1000, height: 60))
        XCTAssertEqual(layout.slots[1].imageRect, CGRect(x: 1040, y: 80, width: 1000, height: 1000))
    }

    func testVerticalLayoutOfIdenticalImages() {
        let layout = ComparisonComposer.layout(beforeSize: square, afterSize: square, axis: .vertical)
        XCTAssertEqual(layout.canvasSize, CGSize(width: 1040, height: 2180))
        XCTAssertEqual(layout.slots[0].labelRect, CGRect(x: 20, y: 20, width: 1000, height: 60))
        XCTAssertEqual(layout.slots[0].imageRect, CGRect(x: 20, y: 80, width: 1000, height: 1000))
        XCTAssertEqual(layout.slots[1].labelRect, CGRect(x: 20, y: 1100, width: 1000, height: 60))
        XCTAssertEqual(layout.slots[1].imageRect, CGRect(x: 20, y: 1160, width: 1000, height: 1000))
    }

    func testCellsAreEqualSizedAndNarrowerImageIsCentered() {
        let layout = ComparisonComposer.layout(
            beforeSize: square,
            afterSize: CGSize(width: 500, height: 1000),
            axis: .horizontal
        )
        // 細い方もセル幅は同じで、写真だけがセル中央に寄る。
        XCTAssertEqual(layout.slots[0].labelRect.width, layout.slots[1].labelRect.width)
        XCTAssertEqual(layout.slots[1].imageRect, CGRect(x: 1290, y: 80, width: 500, height: 1000))
    }

    func testAspectRatioIsPreservedWhenSidesDiffer() {
        let before = CGSize(width: 4032, height: 3024)
        let after = CGSize(width: 1200, height: 1600)
        let layout = ComparisonComposer.layout(beforeSize: before, afterSize: after, axis: .horizontal)
        for (slot, original) in zip(layout.slots, [before, after]) {
            let expected = original.width / original.height
            let actual = slot.imageRect.width / slot.imageRect.height
            XCTAssertEqual(actual, expected, accuracy: 0.001)
        }
    }

    func testLongSideIsCapped() {
        let layout = ComparisonComposer.layout(
            beforeSize: square,
            afterSize: square,
            axis: .horizontal,
            maxLongSide: 1030
        )
        XCTAssertEqual(layout.canvasSize, CGSize(width: 1030, height: 550))
        XCTAssertEqual(layout.slots[0].imageRect, CGRect(x: 10, y: 40, width: 500, height: 500))
        XCTAssertEqual(layout.fontSize, 60 * 0.58 * 0.5, accuracy: 0.001)
    }

    func testDegenerateSizesDoNotProduceInvalidLayout() {
        let layout = ComparisonComposer.layout(
            beforeSize: CGSize(width: 0, height: 0),
            afterSize: CGSize(width: CGFloat.nan, height: 100),
            axis: .vertical
        )
        XCTAssertTrue(layout.canvasSize.width.isFinite)
        XCTAssertTrue(layout.canvasSize.height.isFinite)
        XCTAssertGreaterThan(layout.canvasSize.width, 0)
        XCTAssertGreaterThan(layout.canvasSize.height, 0)
    }
}
