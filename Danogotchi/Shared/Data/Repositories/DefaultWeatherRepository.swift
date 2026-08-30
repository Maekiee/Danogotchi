import Foundation

final class DefaultWeatherRepository {
    private let apiClient: ApiClient
    
    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
}

extension DefaultWeatherRepository: WeatherRepository {
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeather {
        let dto = try await apiClient.request(
            WeatherApiRouter.currentWeather(lat: lat, lon: lon),
            responseType: CurrentWeatherDTO.self
        )
        print(dto)
        return dto.toEntity()
    }
}
