import ClockCore
import SwiftUI

/// UTC からのずれを選んでタイムゾーンを追加するシート。
///
/// 地域名は 400 件以上あって選びにくいので、選択肢は「ずれ」にまとめ、
/// その帯で暮らしている代表的な都市名を補足として並べている。
struct AddZoneView: View {
    /// すでに一覧に入っているゾーン。二重に追加できないよう印を付ける。
    let existing: [ClockZone]
    let onAdd: (ClockZone) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    /// 選択肢は端末が知っているゾーンから作る。画面が出ている間は変わらないので 1 度だけ計算する。
    private let options = OffsetCatalog.options()

    private var filtered: [OffsetOption] {
        let keyword = query.trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty else { return options }
        return options.filter { option in
            option.label.localizedCaseInsensitiveContains(keyword)
                || option.regions.contains { $0.localizedCaseInsensitiveContains(keyword) }
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { option in
                let added = isAdded(option)

                Button {
                    onAdd(ClockZone.fixedOffset(minutes: option.minutes, name: option.regionSummary))
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.label)
                                .font(.body.monospaced())
                                .foregroundStyle(.primary)
                            Text(option.regionSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if added {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(added)
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "ずれ (+09) や都市名 (Tokyo) で絞り込み")
            .navigationTitle("タイムゾーンを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
    }

    /// 同じずれのゾーンがすでに一覧にあるか。UTC / JST のような既定のゾーンも対象にする。
    private func isAdded(_ option: OffsetOption) -> Bool {
        existing.contains { $0.timeZone.secondsFromGMT() == option.minutes * 60 }
    }
}

#Preview {
    AddZoneView(existing: ClockZone.defaults) { _ in }
}
