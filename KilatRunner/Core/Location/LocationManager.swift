import CoreLocation
import Foundation

protocol LocationProvider: AnyObject, Sendable {
    var locationUpdates: AsyncStream<CLLocation> { get }
    func requestAlwaysAuthorization() async -> CLAuthorizationStatus
    func startUpdates()
    func stopUpdates()
}

final class LocationManager: NSObject, LocationProvider, CLLocationManagerDelegate, @unchecked Sendable {
    let locationUpdates: AsyncStream<CLLocation>
    private let yielder: AsyncStream<CLLocation>.Continuation
    private let manager: CLLocationManager
    private var authorizationContinuations: [CheckedContinuation<CLAuthorizationStatus, Never>] = []

    override init() {
        var continuation: AsyncStream<CLLocation>.Continuation!
        self.locationUpdates = AsyncStream { yielder in
            continuation = yielder
        }
        self.yielder = continuation
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
    }

    func requestAlwaysAuthorization() async -> CLAuthorizationStatus {
        let current = manager.authorizationStatus
        if current == .authorizedAlways || current == .denied || current == .restricted {
            return current
        }
        return await withCheckedContinuation { continuation in
            authorizationContinuations.append(continuation)
            if current == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestAlwaysAuthorization()
            }
        }
    }

    func startUpdates() {
        manager.startUpdatingLocation()
    }

    func stopUpdates() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            yielder.yield(location)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        let waiting = authorizationContinuations
        authorizationContinuations.removeAll()
        for continuation in waiting {
            continuation.resume(returning: status)
        }
        if status == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }
}
