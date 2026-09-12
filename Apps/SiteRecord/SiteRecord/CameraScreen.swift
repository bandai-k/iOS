import SiteRecordCore
import SwiftUI
import UIKit

/// 起動直後に出るメイン画面。カメラ、看板、シャッターだけ。
struct CameraScreen: View {
    /// 看板は端末に保存して使い回す。起動時の読み込みは同期で済ませる。
    private static let store = SiteBoardStore()
    private static let timestamp = BoardTimestamp()
    private static let quotaStore = CaptureQuotaStore()

    @StateObject private var camera = CameraController()
    @StateObject private var location = LocationProvider()
    @StateObject private var purchases = PurchaseController()
    @Environment(\.scenePhase) private var scenePhase

    @State private var board: SiteBoard
    @State private var isEditingBoard = false
    @State private var isComparing = false
    @State private var isSaving = false
    @State private var message: String?
    @State private var messageTask: Task<Void, Never>?
    /// 無料で撮れる残り枚数。買い切り版を持っている場合は見ない。
    @State private var quota: CaptureQuota
    @State private var isShowingPaywall = false

    init() {
        _board = State(initialValue: Self.store.load())
        _quota = State(initialValue: Self.quotaStore.load())
    }

    /// いま撮れるか。買い切り版か、その日の無料枠が残っていれば撮れる。
    private var canCapture: Bool {
        purchases.isUnlocked || quota.allowsCapture(at: Date())
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch camera.status {
            case .denied:
                statusView(
                    title: "カメラを使えません",
                    detail: "「設定」＞このアプリ＞カメラ を許可してください。",
                    showsSettingsLink: true
                )
            case .failed(let detail):
                statusView(title: "カメラを起動できません", detail: detail, showsSettingsLink: false)
            case .configuring, .ready:
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
            }

            controls
            toast
        }
        .onAppear {
            camera.start()
            location.start()
        }
        .task { await purchases.load() }
        .onDisappear {
            camera.stop()
            location.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            // ホームに戻っている間はセッションを止め、戻ってきたら即再開する。
            switch phase {
            case .active:
                camera.start()
                location.start()
            case .background:
                camera.stop()
                location.stop()
            default: break
            }
        }
        .sheet(isPresented: $isEditingBoard) {
            BoardEditorView(board: board) { edited in
                board = edited
                Self.store.save(edited)
            }
        }
        .sheet(isPresented: $isComparing) {
            ComparisonView()
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(purchases: purchases)
        }
        .onChange(of: isComparing) { _, comparing in
            // 比較画面を開いている間はカメラを止め、戻ったら即再開する。
            if comparing {
                camera.stop()
            } else {
                camera.start()
            }
        }
        .statusBarHidden()
    }

    // MARK: - 画面パーツ

    private var controls: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                boardButton
                compareButton
            }
            .overlay(alignment: .bottomLeading) {
                remainingBadge
                    .offset(y: 34)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 20) {
                boardPreview
                shutter
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var boardButton: some View {
        Button {
            isEditingBoard = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                Text(board.isEmpty ? "看板を設定" : (board.rows.first?.value ?? "看板を編集"))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.55), in: Capsule())
        }
    }

    private var compareButton: some View {
        Button {
            isComparing = true
        } label: {
            Image(systemName: "rectangle.split.2x1")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.black.opacity(0.55), in: Circle())
        }
        .accessibilityLabel("施工前後の比較画像を作る")
    }

    /// 無料枠の残りを出す。買い切り版を持っていれば出さない。
    @ViewBuilder
    private var remainingBadge: some View {
        if !purchases.isUnlocked {
            let remaining = quota.remaining(at: Date())
            Button {
                isShowingPaywall = true
            } label: {
                Text(remaining > 0 ? "今日はあと \(remaining) 枚" : "今日の無料分は終了")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(remaining > 0 ? .black.opacity(0.55) : Color.accentColor.opacity(0.9), in: Capsule())
            }
        }
    }

    private var boardPreview: some View {
        // 1 秒ごとに時計を進める。画面が見えていない間は更新されない。
        TimelineView(.periodic(from: .now, by: 1)) { context in
            BoardCard(board: board, timestamp: Self.timestamp.string(for: context.date))
                .frame(width: BoardCard.baseWidth)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shutter: some View {
        Button {
            Task { await capture() }
        } label: {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.9), lineWidth: 4)
                    .frame(width: 78, height: 78)
                Circle()
                    .fill(.white)
                    .frame(width: 64, height: 64)
                if isSaving {
                    ProgressView()
                        .tint(.black)
                }
            }
        }
        .disabled(camera.status != .ready || isSaving)
        .opacity(camera.status == .ready && canCapture ? 1 : 0.4)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("撮影")
    }

    private var toast: some View {
        VStack {
            Spacer()
            if let message {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.8), in: Capsule())
                    .transition(.opacity)
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: message)
        .allowsHitTesting(false)
    }

    private func statusView(title: String, detail: String, showsSettingsLink: Bool) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.metering.unknown")
                .font(.largeTitle)
            Text(title).font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if showsSettingsLink, let url = URL(string: UIApplication.openSettingsURLString) {
                Link("設定を開く", destination: url)
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 4)
            }
        }
        .foregroundStyle(.white)
        .padding(32)
    }

    // MARK: - 撮影

    @MainActor
    private func capture() async {
        guard !isSaving else { return }
        // 無料枠を使い切っていれば撮影せず購入画面を出す。
        guard canCapture else {
            isShowingPaywall = true
            return
        }
        isSaving = true
        defer { isSaving = false }

        // シャッターを切った瞬間の時刻を焼き込む。
        let capturedAt = Date()
        do {
            let captured = try await camera.capturePhoto()
            let stamped = PhotoComposer.compose(
                photo: captured.image,
                board: board,
                timestamp: Self.timestamp.string(for: capturedAt)
            )
            // 焼き込んだ後も撮影日時や機種が写真に残るよう、元のメタデータを付けて書き出す。
            // 位置が取れていれば GPS も書く。取れていなくても撮影は止めない。
            let data = try JPEGWriter.data(
                from: stamped,
                metadata: captured.metadata,
                location: location.photoLocation
            )
            try await PhotoLibrarySaver.save(data)
            // 保存できた 1 枚だけを数える。失敗した撮影で枠を減らさない。
            if !purchases.isUnlocked {
                quota = quota.recording(at: capturedAt)
                Self.quotaStore.save(quota)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            show("保存しました")
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            show(error.localizedDescription)
        }
    }

    private func show(_ text: String) {
        message = text
        messageTask?.cancel()
        messageTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            message = nil
        }
    }
}
