import SiteRecordCore
import SwiftUI

/// 無料の 1 日 3 枚を使い切ったときに出す購入画面。
struct PaywallView: View {
    @ObservedObject var purchases: PurchaseController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "camera.badge.clock")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 24)

                VStack(spacing: 8) {
                    Text("今日の無料分を使い切りました")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text("無料では 1 日 \(CaptureQuota.freeDailyLimit) 枚まで撮れます。日付が変わればまた撮れます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    benefit("枚数の制限なしで撮影できます")
                    benefit("買い切りです。月額の支払いはありません")
                    benefit("看板の設定と比較画像はこれまで通り使えます")
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Spacer(minLength: 0)

                if let failure = purchases.failure {
                    Text(failure)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button {
                        Task { await purchases.purchase() }
                    } label: {
                        Group {
                            if purchases.isPurchasing {
                                ProgressView()
                            } else {
                                Text(buyTitle)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(purchases.product == nil || purchases.isPurchasing)

                    Button("購入を復元") {
                        Task { await purchases.restore() }
                    }
                    .font(.subheadline)
                }
            }
            .padding(24)
            .navigationTitle("無制限で撮る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task { await purchases.load() }
            .onChange(of: purchases.isUnlocked) { _, unlocked in
                if unlocked { dismiss() }
            }
        }
    }

    private var buyTitle: String {
        guard let product = purchases.product else { return "価格を読み込み中" }
        return "\(product.displayPrice) で購入"
    }

    private func benefit(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.subheadline)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    PaywallView(purchases: PurchaseController())
}
