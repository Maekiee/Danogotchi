import Foundation

struct CurrentWeatherDTO: Decodable {
    let name: String
    let weather: [WeatherConditionDTO]
    let main: MainWeatherDTO
}

struct WeatherConditionDTO: Decodable {
    let main: String
    let description: String
    let icon: String
}

struct MainWeatherDTO: Decodable {
    let temp: Double
    let feels_like: Double
    let humidity: Int
}

extension CurrentWeatherDTO {
    func toEntity() -> CurrentWeather {
        let condition = weather.first
        return CurrentWeather(
            cityName: name,
            temperature: main.temp,
            feelsLike: main.feels_like,
            humidity: main.humidity,
            condition: condition?.main ?? "",
            description: condition?.description ?? "",
            iconCode: condition?.icon ?? ""
        )
    }
}
