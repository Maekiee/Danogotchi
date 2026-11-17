import Foundation

protocol LocationProviding {
    @MainActor func currentCoordinate() async throws -> Coordinate
}
