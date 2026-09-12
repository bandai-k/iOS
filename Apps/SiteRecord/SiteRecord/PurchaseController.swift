import Foundation
import StoreKit

/// 買い切りの「無制限アンロック」を扱う。
///
/// 購入は 1 種類だけなので、状態も「持っているか / いないか」だけを見る。
@MainActor
final class PurchaseController: ObservableObject {
    /// App Store Connect に登録する商品 ID。
    static let unlockProductID = "jp.nebulab.siterecord.unlock"

    /// 購入済みか。判定できるまでは false。
    @Published private(set) var isUnlocked = false
    /// 表示用の商品 (価格を出すために使う)。取得できていなければ nil。
    @Published private(set) var product: Product?
    @Published private(set) var isPurchasing = false
    /// 直近の失敗の説明。購入画面に出す。
    @Published var failure: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // 別の端末での購入や返金もここで拾えるよう、更新を受け続ける。
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard case let .verified(transaction) = update else { continue }
                await transaction.finish()
                await self?.refresh()
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    /// 商品情報と購入状態を読み直す。
    func load() async {
        await refresh()
        do {
            product = try await Product.products(for: [Self.unlockProductID]).first
        } catch {
            // 価格が出せないだけなので、購入状態の判定は続ける。
            product = nil
        }
    }

    /// 購入する。完了すると `isUnlocked` が true になる。
    func purchase() async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        failure = nil
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case let .success(verification):
                if case let .verified(transaction) = verification {
                    await transaction.finish()
                    await refresh()
                } else {
                    failure = "購入を確認できませんでした"
                }
            case .userCancelled:
                break
            case .pending:
                failure = "購入の承認待ちです"
            @unknown default:
                break
            }
        } catch {
            failure = error.localizedDescription
        }
    }

    /// 機種変更などのあとに購入を復元する。
    func restore() async {
        failure = nil
        do {
            try await AppStore.sync()
            await refresh()
            if !isUnlocked {
                failure = "復元できる購入がありませんでした"
            }
        } catch {
            failure = error.localizedDescription
        }
    }

    private func refresh() async {
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement,
               transaction.productID == Self.unlockProductID,
               transaction.revocationDate == nil {
                isUnlocked = true
                return
            }
        }
        isUnlocked = false
    }
}
