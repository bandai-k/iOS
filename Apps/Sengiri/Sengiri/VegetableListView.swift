import SengiriCore
import SwiftUI

/// 野菜を選んで、千切り回数を決める画面。
struct VegetableListView: View {
    private static let settings = ChopSettingsStore()
    private static let records = ChopRecordStore()

    @State private var counts: [String: Int] = [:]
    @State private var bests: [String: ChopRecord] = [:]
    @State private var playing: Vegetable?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Vegetable.allCases) { vegetable in
                        row(for: vegetable)
                    }
                } footer: {
                    Text("タップ 1 回で 1 カット。最初のタップで計測が始まり、目標回数のタップで止まります。")
                }

                Section {
                    Button("記録をすべて消す", role: .destructive) {
                        Self.records.reset()
                        reload()
                    }
                    .disabled(bests.isEmpty)
                }
            }
            .navigationTitle("千切り")
            .navigationDestination(item: $playing) { vegetable in
                ChopGameView(vegetable: vegetable, target: cutCount(for: vegetable))
            }
        }
        .onAppear(perform: reload)
    }

    private func row(for vegetable: Vegetable) -> some View {
        let count = cutCount(for: vegetable)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VegetableBadge(vegetable: vegetable)
                VStack(alignment: .leading, spacing: 2) {
                    Text(vegetable.name)
                        .font(.headline)
                    Text(bestText(for: vegetable, count: count))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("スタート") { playing = vegetable }
                    .buttonStyle(.borderedProminent)
            }

            Stepper(value: binding(for: vegetable), in: ChopRules.cutCountRange, step: 5) {
                Text("千切り \(count) 回")
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 状態

    private func cutCount(for vegetable: Vegetable) -> Int {
        counts[vegetable.rawValue] ?? vegetable.defaultCutCount
    }

    private func binding(for vegetable: Vegetable) -> Binding<Int> {
        Binding(
            get: { cutCount(for: vegetable) },
            set: { newValue in
                let clamped = ChopRules.clamp(newValue)
                counts[vegetable.rawValue] = clamped
                Self.settings.setCutCount(clamped, for: vegetable)
                // 回数が変わるとベストタイムも別物になるので出し直す。
                bests[vegetable.rawValue] = Self.records.best(for: vegetable, cutCount: clamped)
            }
        )
    }

    private func bestText(for vegetable: Vegetable, count: Int) -> String {
        guard let best = bests[vegetable.rawValue], best.cutCount == count else {
            return "記録なし"
        }
        return "ベスト \(ChopTimeFormatter.string(best.seconds)) 秒"
    }

    private func reload() {
        var loadedCounts: [String: Int] = [:]
        var loadedBests: [String: ChopRecord] = [:]
        for vegetable in Vegetable.allCases {
            let count = Self.settings.cutCount(for: vegetable)
            loadedCounts[vegetable.rawValue] = count
            loadedBests[vegetable.rawValue] = Self.records.best(for: vegetable, cutCount: count)
        }
        counts = loadedCounts
        bests = loadedBests
    }
}

#Preview {
    VegetableListView()
}
