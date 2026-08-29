import Foundation

enum APIConfig {
    private static func value<T>(_ key: String) -> T {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? T else {
            fatalError("Info.plist에 \(key) 키가 없거나 타입이 맞지 않습니다.")
        }
        return value
    }
    
    // MARK: - Unsplash
    enum Unsplash {
        private static let domain: String = APIConfig.value("UnsplashBaseURL")
        private static let apiKeys: [String] = APIConfig.value("UnsplashAPIKeys")
        
        static let baseURL: String = "https://\(domain)"
        static var apiKey: String { apiKeys.randomElement()! }
    }
    
    // MARK: - OpenWeatherMap
    enum Weather {
        private static let domain: String = APIConfig.value("WeatherBaseURL")
        
        static let baseURL: String = "https://\(domain)"
        static let apiKey: String = APIConfig.value("WeatherAPIKey")
    }
}
