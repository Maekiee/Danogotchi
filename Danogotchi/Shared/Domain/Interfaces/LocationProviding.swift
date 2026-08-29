import Foundation

protocol LocationProviding {
    @MainActor func currentCoordinate() async throws -> Coordinate
}

enum LocationError: Error {
    case permissionDenied
    case requestInProgress
}
