import CoreGraphics
import Foundation
import ImageIO

/// 撮影位置 1 点分。`CoreLocation` に依存せず持てるようにした値。
public struct PhotoLocation: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
    /// 標高 (m)。海面より下は負。
    public let altitude: Double?
    /// 水平方向の誤差 (m)。負なら測れていない。
    public let horizontalAccuracy: Double?
    /// 測位した時刻。
    public let timestamp: Date

    public init(
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        horizontalAccuracy: Double? = nil,
        timestamp: Date
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
    }

    /// 緯度経度として成り立っているか。測位できていない値を写真に書かないための確認。
    public var isValid: Bool {
        latitude.isFinite && longitude.isFinite
            && abs(latitude) <= 90 && abs(longitude) <= 180
            && !(latitude == 0 && longitude == 0)
    }
}

/// 撮影位置を EXIF の GPS 辞書にする。
///
/// EXIF の GPS は「絶対値 + 方角の記号」で持ち、時刻は UTC と決まっているので、
/// `CoreLocation` から来た値をそのまま入れずにここで変換する。
public enum GPSMetadata {
    /// 写真に書き込む GPS 辞書。測位できていない位置なら `nil`。
    public static func dictionary(for location: PhotoLocation) -> [String: Any]? {
        guard location.isValid else { return nil }

        var gps: [String: Any] = [
            kCGImagePropertyGPSLatitude as String: abs(location.latitude),
            kCGImagePropertyGPSLatitudeRef as String: location.latitude < 0 ? "S" : "N",
            kCGImagePropertyGPSLongitude as String: abs(location.longitude),
            kCGImagePropertyGPSLongitudeRef as String: location.longitude < 0 ? "W" : "E",
            kCGImagePropertyGPSTimeStamp as String: timeFormatter.string(from: location.timestamp),
            kCGImagePropertyGPSDateStamp as String: dateFormatter.string(from: location.timestamp)
        ]

        if let altitude = location.altitude, altitude.isFinite {
            gps[kCGImagePropertyGPSAltitude as String] = abs(altitude)
            // 0 = 海面より上、1 = 海面より下。
            gps[kCGImagePropertyGPSAltitudeRef as String] = altitude < 0 ? 1 : 0
        }

        if let accuracy = location.horizontalAccuracy, accuracy.isFinite, accuracy >= 0 {
            gps[kCGImagePropertyGPSHPositioningError as String] = accuracy
        }

        return gps
    }

    /// GPS の時刻は UTC の `HH:mm:ss`。
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// GPS の日付は UTC の `yyyy:MM:dd`。
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy:MM:dd"
        return formatter
    }()
}
