import Foundation

enum APIConfig {
    private static let domain: String = value("UnsplashBaseURL")
    private static let apiKeys: [String] = value("UnsplashAPIKeys")
    
    private static func value<T>(_ key: String) -> T {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? T else {
            fatalError("Info.plist에 \(key) 키가 없거나 타입이 맞지 않습니다.")
        }
        return value
    }
    
    static let baseURL: String = "https://\(domain)"
    static var apiKey: String { apiKeys.randomElement()! }
}
