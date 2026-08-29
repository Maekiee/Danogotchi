import CoreLocation

@MainActor
final class DeviceLocationProvider: NSObject, LocationProviding {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Coordinate, Error>?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func currentCoordinate() async throws -> Coordinate {
        guard continuation == nil else { throw LocationError.requestInProgress }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            requestLocationIfAuthorized()
        }
    }
    
    private func requestLocationIfAuthorized() {
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
        requestLocationIfAuthorized()
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
