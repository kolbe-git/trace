import Foundation
import CoreLocation
import Observation

/// GPS 定位与权限封装。运动会话通过 `onLocation` 拿到过滤后的有效定位点。
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var latestLocation: CLLocation?

    /// 每个"有效"定位点的回调（已过滤精度差/过旧的点）
    var onLocation: ((CLLocation) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .fitness
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        // Info.plist 已含 UIBackgroundModes=location，可安全开启后台定位
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func start() { manager.startUpdatingLocation() }
    func stop()  { manager.stopUpdatingLocation() }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations where isValid(location) {
            latestLocation = location
            onLocation?(location)
        }
    }

    /// 过滤：精度有效且优于 50m，且不是太旧的缓存点
    private func isValid(_ location: CLLocation) -> Bool {
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 50 else { return false }
        return abs(location.timestamp.timeIntervalSinceNow) < 10
    }
}
