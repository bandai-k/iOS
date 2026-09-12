import CoreLocation
import Foundation
import SpeedometerCore

/// 位置情報から速度を受け取って画面に流すところ。
///
/// 速度だけが欲しいので、位置そのものは保持しない。
@MainActor
final class SpeedProvider: NSObject, ObservableObject {
    /// いまの速度。測れていない間は `.unavailable`。
    @Published private(set) var reading: SpeedReading = .unavailable
    /// 位置情報の許可の状態。案内文の出し分けに使う。
    @Published private(set) var authorization: CLAuthorizationStatus

    private let manager = CLLocationManager()
    /// 最後に速度を受け取った時刻。途切れたことに気付くために持っておく。
    private var lastUpdate: Date?
    private var staleTimer: Timer?

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        // 移動中の速度を追うので、精度は最優先。
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .automotiveNavigation
        // 速度はわずかな移動でも変わるため、距離でのフィルタはかけない。
        manager.distanceFilter = kCLDistanceFilterNone
    }

    /// 許可を求めたうえで計測を始める。画面が出ている間だけ動かす。
    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
        startStaleTimer()
    }

    func stop() {
        manager.stopUpdatingLocation()
        staleTimer?.invalidate()
        staleTimer = nil
        lastUpdate = nil
        reading = .unavailable
    }

    /// 更新が途切れたら表示を「測定中」に戻す。トンネルで古い速度が出たままにならないように。
    private func startStaleTimer() {
        staleTimer?.invalidate()
        staleTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.reading.isAvailable else { return }
                if SpeedFreshness.isStale(lastUpdate: self.lastUpdate) {
                    self.reading = .unavailable
                }
            }
        }
    }

    /// 許可が無くて計測できない状態か。
    var isDenied: Bool {
        authorization == .denied || authorization == .restricted
    }
}

extension SpeedProvider: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let speed = locations.last?.speed else { return }
        Task { @MainActor in
            lastUpdate = Date()
            reading = .fromLocation(metersPerSecond: speed)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorization = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastUpdate = nil
            reading = .unavailable
        }
    }
}
