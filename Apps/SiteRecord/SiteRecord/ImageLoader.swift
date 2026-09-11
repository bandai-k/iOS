import ImageIO
import UIKit

/// カメラロールから読み込んだ画像を、扱いやすい大きさに落として返す。
///
/// 記録写真は 12MP 前後あり、2 枚そのまま展開すると比較画像の合成でメモリを食うので、
/// 読み込みの時点で長辺を制限する。EXIF の回転もここで解決しておく。
enum ImageLoader {
    static func image(from data: Data, maxPixelSize: CGFloat = 3000) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }
}
