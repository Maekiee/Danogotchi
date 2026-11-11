import Foundation

protocol FetchCurrentWeatherUseCase {
    @MainActor func getWeather() async throws -> CurrentWeather
}

final class DefaultFetchCurrentWeatherUseCase: FetchCurrentWeatherUseCase {
    private let locationProvider: LocationProviding
    private let weatherRepository: WeatherRepository
    
    init(
        locationProvider: LocationProviding,
        weatherRepository: WeatherRepository
    ) {
        self.locationProvider = locationProvider
        self.weatherRepository = weatherRepository
    }
    
    @MainActor
    func getWeather() async throws -> CurrentWeather {
        let coordinate = try await locationProvider.currentCoordinate()
        return try await weatherRepository.fetchCurrentWeather(
            lat: coordinate.latitude,
            lon: coordinate.longitude
        )
    }
}
