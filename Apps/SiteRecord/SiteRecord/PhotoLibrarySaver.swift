import Photos
import UIKit
import UniformTypeIdentifiers

enum PhotoLibraryError: LocalizedError {
    case denied

    var errorDescription: String? {
        "写真へのアクセスが許可されていません"
    }
}

/// 書き出し済みの JPEG をカメラロールに保存する。読み出しはしないので追加専用の権限で足りる。
enum PhotoLibrarySaver {
    static func save(_ data: Data) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.denied
        }

        // データを直接渡すと写真アプリ側で再エンコードされ、EXIF と GPS が落ちる。
        // 一時ファイルにしてから渡すと、書き出したバイト列がそのまま資産になる。
        let url = FileManager.default.temporaryDirectory
            .appending(path: "capture-\(UUID().uuidString).jpg")
        try data.write(to: url)

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                // 取り込み後に一時ファイルを残さない。
                options.shouldMoveFile = true
                options.uniformTypeIdentifier = UTType.jpeg.identifier
                request.addResource(with: .photo, fileURL: url, options: options)
            }
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    /// メタデータを持たない画像 (比較画像など) を保存する。
    static func save(_ image: UIImage) async throws {
        try await save(JPEGWriter.data(from: image))
    }
}
