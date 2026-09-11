import Photos
import UIKit

enum PhotoLibraryError: LocalizedError {
    case denied
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .denied:
            return "写真へのアクセスが許可されていません"
        case .encodingFailed:
            return "写真の書き出しに失敗しました"
        }
    }
}

/// 合成済みの写真をカメラロールに保存する。読み出しはしないので追加専用の権限で足りる。
enum PhotoLibrarySaver {
    static func save(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.denied
        }
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw PhotoLibraryError.encodingFailed
        }
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
        }
    }
}
