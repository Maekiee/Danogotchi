import Foundation

enum APIHeader {
    case apiKey
    case applicationJSON
    
    var field: (name: String, value: String) {
        switch self {
        case .apiKey: return ("Authorization", "Client-ID \(APIConfig.apiKey)")
        case .applicationJSON: return ("Content-Type", "application/json")
        }
    }
    static func dict(_ headers: [APIHeader]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: headers.map { ($0.field.name, $0.field.value)})
    }
}
