import Foundation

enum WeatherApiRouter: Endpoint {
    case currentWeather(lat: Double, lon: Double)
    
    var baseURL: String { APIConfig.Weather.baseURL }
    
    var path: String {
        switch self {
        case .currentWeather: return "/weather"
        }
    }
    
    var method: HTTPMethod { .get }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case let .currentWeather(lat, lon):
            return [
                URLQueryItem(name: "lat", value: "\(lat)"),
                URLQueryItem(name: "lon", value: "\(lon)"),
                URLQueryItem(name: "appid", value: APIConfig.Weather.apiKey),
                URLQueryItem(name: "units", value: "metric"),
                URLQueryItem(name: "lang", value: "kr"),
            ]
        }
    }
}
