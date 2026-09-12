import CoreLocation
import Foundation
import SiteRecordCore

/// 撮影位置を EXIF に書くための現在地を用意する。
///
/// 写真 1 枚ごとに測り直すのではなく、カメラ画面が出ている間だけ更新を受け続け、
/// シャッターの瞬間はその時点で持っている位置を使う。
@MainActor
final class LocationProvider: NSObject, ObservableObject {
    /// これより古い位置は写真に書かない秒数。現場を移動しながら撮るので長く持たない。
    private static let maxAge: TimeInterval = 60

    /// 位置情報が使える状態か。画面の案内に使う。
    @Published private(set) var isAvailable = false

    private let manager = CLLocationManager()
    private var latest: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// 許可を求めたうえで測位を始める。拒否されていても撮影自体は続けられる。
    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isAvailable = true
            manager.startUpdatingLocation()
        default:
            isAvailable = false
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    /// いま写真に書ける位置。測れていない・古すぎる場合は `nil`。
    var photoLocation: PhotoLocation? {
        guard let latest else { return nil }
        guard Date().timeIntervalSince(latest.timestamp) <= Self.maxAge else { return nil }

        let location = PhotoLocation(
            latitude: latest.coordinate.latitude,
            longitude: latest.coordinate.longitude,
            altitude: latest.verticalAccuracy >= 0 ? latest.altitude : nil,
            horizontalAccuracy: latest.horizontalAccuracy,
            timestamp: latest.timestamp
        )
        return location.isValid ? location : nil
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            latest = location
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            let granted = status == .authorizedWhenInUse || status == .authorizedAlways
            isAvailable = granted
            if granted {
                manager.startUpdatingLocation()
            } else {
                latest = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            latest = nil
        }
    }
}
