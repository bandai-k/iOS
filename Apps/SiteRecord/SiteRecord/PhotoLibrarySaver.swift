import Photos
import UIKit

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
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            // EXIF ごと保存したいので、UIImage ではなく書き出し済みのデータを渡す。
            request.addResource(with: .photo, data: data, options: nil)
        }
    }

    /// メタデータを持たない画像 (比較画像など) を保存する。
    static func save(_ image: UIImage) async throws {
        try await save(JPEGWriter.data(from: image))
    }
}
