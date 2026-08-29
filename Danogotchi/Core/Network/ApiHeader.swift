import Foundation

enum APIHeader {
    case unsplashKey
    case applicationJSON
    
    var field: (name: String, value: String) {
        switch self {
        case .unsplashKey: return ("Authorization", "Client-ID \(APIConfig.Unsplash.apiKey)")
        case .applicationJSON: return ("Content-Type", "application/json")
        }
    }
    static func dict(_ headers: [APIHeader]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: headers.map { ($0.field.name, $0.field.value)})
    }
}
