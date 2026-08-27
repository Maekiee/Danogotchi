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

enum APIHeader {
    case apiKey
    case applicationJSON
    
    var field: (name: String, value: String) {
        switch self {
        case .apiKey: return ("Authorization", "client_id \(APIConfig.apiKey)")
        case .applicationJSON: return ("Content-Type", "application/json")
        }
    }
    static func dict(_ headers: [APIHeader]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: headers.map { ($0.field.name, $0.field.value)})
    }
}


protocol ApiClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint, type: T.Type) async throws -> T
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

protocol Endpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    var queryItems: [URLQueryItem]? { get }
}

extension Endpoint {
    var headers: [String:String] { APIHeader.dict([.apiKey, .applicationJSON]) }
    var body: Data? { nil }
    var queryItems: [URLQueryItem]? { nil }
}

final class ApiClient: ApiClientProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func request<T>(_ endpoint: any Endpoint, type: T.Type) async throws -> T where T : Decodable {
        <#code#>
    }
}
