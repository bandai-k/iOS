import ClockCore
import SwiftUI

/// 入力した日時を、選んでおいたタイムゾーンすべてで見る画面。
struct ContentView: View {
    /// 24 時間表記 / AM・PM 表記の選択。次回起動時も同じ表記で出したいので端末に保存する。
    @AppStorage("hourStyle") private var hourStyleRaw: String = HourStyle.twentyFour.rawValue

    /// `DatePicker` が読み書きする日時。端末のタイムゾーンで見たときの「見た目の日時」として扱う。
    @State private var wallInput: Date = .now
    /// 表示するタイムゾーンの一覧。追加・削除の結果は端末に保存する。
    @State private var zones: [ClockZone] = ClockZone.defaults
    /// 入力した日時をどのゾーンの時刻とみなすか。
    @State private var sourceZone: ClockZone = .jst
    @State private var isEditing = false
    @State private var isAddingZone = false

    private let store = ClockZoneListStore()

    private var hourStyle: HourStyle {
        HourStyle(rawValue: hourStyleRaw) ?? .twentyFour
    }

    /// 見た目の日時を基準ゾーンの時刻として読み替えた、実際の瞬間。
    private var instant: Date {
        ClockConverter.reinterpret(wallInput, from: .current, to: sourceZone.timeZone)
    }

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(spacing: 24) {
                    hourStylePicker
                    input
                    zoneList
                    note
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            zones = store.load()
            if !zones.contains(sourceZone) {
                sourceZone = zones.first ?? .utc
            }
            resetToNow()
        }
        .sheet(isPresented: $isAddingZone) {
            AddZoneView(existing: zones) { zone in
                update(zones: ClockZoneList.adding(zone, to: zones))
            }
        }
    }

    private var hourStylePicker: some View {
        Picker("表示形式", selection: $hourStyleRaw) {
            ForEach(HourStyle.allCases) { style in
                Text(style.label).tag(style.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }

    private var input: some View {
        VStack(spacing: 12) {
            HStack {
                Text("入力")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("入力する時刻のタイムゾーン", selection: $sourceZone) {
                    ForEach(zones) { zone in
                        Text(zone.id).tag(zone)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Button("いま", action: resetToNow)
                    .buttonStyle(.bordered)
            }

            DatePicker(
                "日時",
                selection: $wallInput,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            // DatePicker 自体は端末のタイムゾーンで表示される。入力値は上の選択に応じて読み替える。
            .environment(\.locale, Locale(identifier: hourStyle == .twelve ? "en_US" : "ja_JP"))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var zoneList: some View {
        VStack(spacing: 16) {
            HStack {
                Text("タイムゾーン")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(isEditing ? "完了" : "編集") {
                    withAnimation { isEditing.toggle() }
                }
                .font(.subheadline)
            }

            ForEach(zones) { zone in
                ClockCardView(
                    zone: zone,
                    date: instant,
                    hourStyle: hourStyle,
                    isHighlighted: zone == sourceZone
                )
                .overlay(alignment: .topTrailing) {
                    if isEditing, zone.isRemovable {
                        removeButton(for: zone)
                    }
                }
            }

            Button {
                isAddingZone = true
            } label: {
                Label("タイムゾーンを追加", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
        }
    }

    private func removeButton(for zone: ClockZone) -> some View {
        Button {
            withAnimation { update(zones: ClockZoneList.removing(zone, from: zones)) }
        } label: {
            Image(systemName: "minus.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .red)
        }
        .buttonStyle(.plain)
        .padding(10)
        .accessibilityLabel("\(zone.id) を削除")
    }

    private var note: some View {
        Text("枠が付いている方が入力したタイムゾーンです。UTC は基準なので削除できません。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 一覧を差し替えて保存する。入力に使っていたゾーンが消えた場合は先頭に寄せる。
    private func update(zones newZones: [ClockZone]) {
        zones = newZones
        store.save(newZones)
        if !newZones.contains(sourceZone) {
            sourceZone = newZones.first ?? .utc
        }
    }

    /// 入力欄を「基準ゾーンでのいまの時刻」に合わせる。秒は切り捨てて 00 にする。
    private func resetToNow() {
        wallInput = ClockConverter.alignedToMinute(
            ClockConverter.reinterpret(.now, from: sourceZone.timeZone, to: .current)
        )
    }
}

private struct BackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.18),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .center
        )
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
