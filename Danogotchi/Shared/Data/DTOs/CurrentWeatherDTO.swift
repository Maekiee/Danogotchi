import Foundation

struct CurrentWeatherDTO: Decodable {
    let name: String
    let weather: [WeatherConditionDTO]
    let main: MainWeatherDTO
}

struct WeatherConditionDTO: Decodable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct MainWeatherDTO: Decodable {
    let temp: Double
    let feelsLike: Double
    let humidity: Int

    enum CodingKeys: String, CodingKey {
        case temp, humidity
        case feelsLike = "feels_like"
    }
}

extension CurrentWeatherDTO {
    func toEntity() -> CurrentWeather {
        let condition = weather.first
        return CurrentWeather(
            cityName: name,
            temperature: main.temp,
            feelsLike: main.feelsLike,
            humidity: main.humidity,
            weatherType: condition.map { WeatherType(id: $0.id) } ?? .clear,
            description: condition?.description ?? "",
            iconCode: condition?.icon ?? ""
        )
    }
}
