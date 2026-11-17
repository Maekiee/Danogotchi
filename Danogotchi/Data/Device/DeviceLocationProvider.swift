import CoreLocation

@MainActor
final class DeviceLocationProvider: NSObject, LocationProviding {
    private var manager: CLLocationManager?
    private var continuation: CheckedContinuation<Coordinate, Error>?
    
    /// 생성 시점에는 메인 격리 상태를 건드리지 않는다 — 조립부(AppDIContainer)를 nonisolated로 두기 위해서다
    nonisolated override init() {
        super.init()
    }
    
    func currentCoordinate() async throws -> Coordinate {
        guard continuation == nil else { throw LocationError.requestInProgress }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            requestLocationIfAuthorized(makeManagerIfNeeded())
        }
    }
    
    private func makeManagerIfNeeded() -> CLLocationManager {
        if let manager { return manager }
        
        let created = CLLocationManager()
        created.delegate = self
        created.desiredAccuracy = kCLLocationAccuracyKilometer
        manager = created
        return created
    }
    
    private func requestLocationIfAuthorized(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            resume(with: .failure(LocationError.permissionDenied))
        @unknown default:
            resume(with: .failure(LocationError.permissionDenied))
        }
    }
    
    private func resume(with result: Result<Coordinate, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }
}

extension DeviceLocationProvider: @preconcurrency CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        requestLocationIfAuthorized(manager)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        resume(with: .success(
            Coordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        ))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(with: .failure(error))
    }
}
