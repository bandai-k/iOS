import PhotosUI
import SiteRecordCore
import SwiftUI

/// カメラロールから施工前・施工後の写真を選び、1 枚の比較画像にして保存する。
struct ComparisonView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var beforeItem: PhotosPickerItem?
    @State private var afterItem: PhotosPickerItem?
    @State private var beforeImage: UIImage?
    @State private var afterImage: UIImage?
    @State private var axis: ComparisonAxis = .horizontal
    @State private var composed: UIImage?
    @State private var isWorking = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("並べ方", selection: $axis) {
                        Text("横に並べる").tag(ComparisonAxis.horizontal)
                        Text("縦に並べる").tag(ComparisonAxis.vertical)
                    }
                    .pickerStyle(.segmented)

                    HStack(alignment: .top, spacing: 12) {
                        picker(title: "施工前", image: beforeImage, selection: $beforeItem)
                        picker(title: "施工後", image: afterImage, selection: $afterItem)
                    }

                    preview

                    if let message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(16)
            }
            .navigationTitle("施工前後の比較")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(composed == nil || isWorking)
                }
            }
        }
        .onChange(of: beforeItem) { _, item in
            Task { await loadBefore(item) }
        }
        .onChange(of: afterItem) { _, item in
            Task { await loadAfter(item) }
        }
        .onChange(of: axis) { _, _ in
            compose()
        }
    }

    // MARK: - 画面パーツ

    private func picker(title: String, image: UIImage?, selection: Binding<PhotosPickerItem?>) -> some View {
        PhotosPicker(selection: selection, matching: .images, photoLibrary: .shared()) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.gray.opacity(0.2))
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                            Text("写真を選ぶ")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var preview: some View {
        if let composed {
            VStack(spacing: 8) {
                Image(uiImage: composed)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text("\(Int(composed.size.width)) × \(Int(composed.size.height)) px")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(spacing: 8) {
                if isWorking {
                    ProgressView()
                } else {
                    Image(systemName: "rectangle.split.2x1")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("2 枚選ぶとプレビューが出ます")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160)
        }
    }

    // MARK: - 処理

    @MainActor
    private func loadBefore(_ item: PhotosPickerItem?) async {
        beforeImage = await image(from: item)
        compose()
    }

    @MainActor
    private func loadAfter(_ item: PhotosPickerItem?) async {
        afterImage = await image(from: item)
        compose()
    }

    /// 選ばれた写真を読み込む。失敗したら理由を画面に出して nil を返す。
    @MainActor
    private func image(from item: PhotosPickerItem?) async -> UIImage? {
        guard let item else { return nil }
        isWorking = true
        defer { isWorking = false }
        message = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = ImageLoader.image(from: data) else {
                message = "写真を読み込めませんでした"
                return nil
            }
            return image
        } catch {
            message = error.localizedDescription
            return nil
        }
    }

    @MainActor
    private func save() async {
        guard let composed else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await PhotoLibrarySaver.save(composed)
            message = "保存しました"
        } catch {
            message = error.localizedDescription
        }
    }

    /// 2 枚そろったら合成し直す。片方だけならプレビューを消す。
    @MainActor
    private func compose() {
        guard let beforeImage, let afterImage else {
            composed = nil
            return
        }
        composed = ComparisonRenderer.render(before: beforeImage, after: afterImage, axis: axis)
    }
}

#Preview {
    ComparisonView()
}
