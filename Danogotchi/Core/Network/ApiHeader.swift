import Foundation

enum APIHeader {
    case applicationJSON
    
    var field: (name: String, value: String) {
        switch self {
        case .applicationJSON: return ("Content-Type", "application/json")
        }
    }
    static func dict(_ headers: [APIHeader]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: headers.map { ($0.field.name, $0.field.value)})
    }
}
