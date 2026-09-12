import CoreGraphics
import Foundation
import ImageIO

/// 撮影時のメタデータ (EXIF / TIFF) を、看板を焼き込んだ後の画像に付け直せる形に整える。
///
/// 合成では写真を上向きのビットマップに描き直すので、元の向きや画素数のまま引き継ぐと
/// 実際の画像と食い違う。ここで向きと画素数だけ書き換え、撮影日時や機種はそのまま残す。
public enum PhotoMetadata {
    /// 上向き (回転なし) を表す EXIF の向き。
    public static let orientationUp = 1

    /// 合成後の画像に付けるメタデータを作る。
    ///
    /// - Parameters:
    ///   - original: `AVCapturePhoto.metadata` などから受け取った撮影時のメタデータ。
    ///   - pixelSize: 合成後の画像の画素数。
    ///   - software: 記録しておくアプリ名。`nil` なら元の値のまま。
    public static func forComposite(
        original: [String: Any],
        pixelSize: CGSize,
        software: String? = nil
    ) -> [String: Any] {
        var metadata = original

        let width = Int(pixelSize.width.rounded())
        let height = Int(pixelSize.height.rounded())

        metadata[kCGImagePropertyPixelWidth as String] = width
        metadata[kCGImagePropertyPixelHeight as String] = height
        metadata[kCGImagePropertyOrientation as String] = orientationUp

        var exif = dictionary(in: metadata, for: kCGImagePropertyExifDictionary)
        exif[kCGImagePropertyExifPixelXDimension as String] = width
        exif[kCGImagePropertyExifPixelYDimension as String] = height
        metadata[kCGImagePropertyExifDictionary as String] = exif

        var tiff = dictionary(in: metadata, for: kCGImagePropertyTIFFDictionary)
        tiff[kCGImagePropertyTIFFOrientation as String] = orientationUp
        if let software {
            tiff[kCGImagePropertyTIFFSoftware as String] = software
        }
        metadata[kCGImagePropertyTIFFDictionary as String] = tiff

        // 元の画像から作られた縮小版は合成後の見た目と違うので落とす。
        metadata[kCGImagePropertyThumbnailImages as String] = nil

        return metadata
    }

    private static func dictionary(in metadata: [String: Any], for key: CFString) -> [String: Any] {
        metadata[key as String] as? [String: Any] ?? [:]
    }
}
