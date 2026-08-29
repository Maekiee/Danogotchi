import Foundation

protocol WeatherRepository {
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeather
}
