import SiteRecordCore
import StoreKit
import StoreKitTest
import XCTest
@testable import SiteRecord

/// 買い切りの購入まわり。
///
/// App Store Connect に商品を登録しなくても試せるよう、`Products.storekit` を
/// StoreKit のテストセッションに読ませて、実際に購入を通す。
@MainActor
final class PurchaseControllerTests: XCTestCase {
    private var session: SKTestSession!

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "Products")
        session.resetToDefaultState()
        session.clearTransactions()
        // 購入の確認ダイアログは出さず、そのまま成立させる。
        session.disableDialogs = true

        // StoreKit のテスト構成が適用されない環境（xcodebuild から実行した場合など）では、
        // 商品が 1 つも見えない。本物の StoreKit に問い合わせに行ってしまうため、
        // そこで止まらないよう、その場合はテストを飛ばす。
        let products = try await Product.products(for: [PurchaseController.unlockProductID])
        try XCTSkipIf(
            products.isEmpty,
            "StoreKit のテスト構成を適用できない環境です。Xcode から実行してください"
        )
    }

    override func tearDown() async throws {
        session.clearTransactions()
        session = nil
    }

    func testStartsLockedAndFindsTheProduct() async {
        let purchases = PurchaseController()
        await purchases.load()

        XCTAssertFalse(purchases.isUnlocked, "買う前は制限がかかったまま")
        XCTAssertEqual(purchases.product?.id, PurchaseController.unlockProductID)
        XCTAssertFalse(purchases.product?.displayPrice.isEmpty ?? true, "価格が表示できる")
    }

    func testPurchaseUnlocks() async {
        let purchases = PurchaseController()
        await purchases.load()
        XCTAssertFalse(purchases.isUnlocked)

        await purchases.purchase()

        XCTAssertTrue(purchases.isUnlocked, "購入したら制限が外れる")
        XCTAssertNil(purchases.failure)
    }

    func testPurchaseSurvivesRelaunch() async {
        let purchases = PurchaseController()
        await purchases.load()
        await purchases.purchase()
        XCTAssertTrue(purchases.isUnlocked)

        // 起動し直した状態を作り、購入済みとして復元されるか確かめる。
        let relaunched = PurchaseController()
        await relaunched.load()
        XCTAssertTrue(relaunched.isUnlocked, "次回起動時も購入済みのまま")
    }

    func testRestoreWithoutPurchaseReportsNothingToRestore() async {
        let purchases = PurchaseController()
        await purchases.load()

        await purchases.restore()

        XCTAssertFalse(purchases.isUnlocked)
        XCTAssertNotNil(purchases.failure, "復元できるものが無いことを伝える")
    }

    func testRefundRelocks() async throws {
        let purchases = PurchaseController()
        await purchases.load()
        await purchases.purchase()
        XCTAssertTrue(purchases.isUnlocked)

        // 返金されたら、次に確認したときに制限が戻る。
        for transaction in session.allTransactions() {
            try session.refundTransaction(identifier: UInt(transaction.identifier))
        }
        let relaunched = PurchaseController()
        await relaunched.load()
        XCTAssertFalse(relaunched.isUnlocked, "返金後は制限が戻る")
    }
}

/// 無料枠と購入状態の組み合わせで、撮影できるかどうかが変わること。
final class CaptureGateTests: XCTestCase {
    private let now = Date()

    func testFreeQuotaGatesCapture() {
        var quota = CaptureQuota.empty(at: now)
        for _ in 0..<CaptureQuota.freeDailyLimit {
            XCTAssertTrue(quota.allowsCapture(at: now))
            quota = quota.recording(at: now)
        }
        XCTAssertFalse(quota.allowsCapture(at: now), "無料枠を使い切ると撮れない")
    }
}
