import ImageIO
import SiteRecordCore
import UIKit
import UniformTypeIdentifiers

/// 画像を JPEG のデータにする。撮影時のメタデータを渡せば EXIF ごと書き出す。
///
/// `UIImage.jpegData(compressionQuality:)` は EXIF を落としてしまうため、
/// 記録写真の撮影日時や機種を残したい場合はこちらを通す。
enum JPEGWriter {
    enum WriteError: LocalizedError {
        case encodingFailed

        var errorDescription: String? {
            "写真の書き出しに失敗しました"
        }
    }

    static let quality: CGFloat = 0.9

    /// - Parameter metadata: 撮影時のメタデータ。`nil` ならメタデータなしで書き出す。
    static func data(from image: UIImage, metadata: [String: Any]? = nil) throws -> Data {
        guard let cgImage = image.cgImage else { throw WriteError.encodingFailed }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw WriteError.encodingFailed
        }

        var properties: [String: Any] = metadata.map {
            PhotoMetadata.forComposite(
                original: $0,
                pixelSize: CGSize(width: cgImage.width, height: cgImage.height),
                software: softwareName
            )
        } ?? [:]
        properties[kCGImageDestinationLossyCompressionQuality as String] = quality

        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw WriteError.encodingFailed }

        return output as Data
    }

    /// EXIF に残すアプリ名。
    private static var softwareName: String {
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SiteRecord"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version.map { "\(name) \($0)" } ?? name
    }
}
