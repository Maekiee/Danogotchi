import Foundation

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
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    var requiresAuth: Bool { get }
    var queryItems: [URLQueryItem]? { get }
}

extension Endpoint {
    var headers: [String: String] {
        return [
            "Content-Type":"application/json",
        ]
    }
    
    var body: Data? {
        return nil
    }
    
    // 기본값: 인증 필요 (실수 방지)
    var requiresAuth: Bool {
        return true
    }
    
    var queryItems: [URLQueryItem]? { return nil }
}

final class ApiClient: ApiClientProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func request<T>(_ endpoint: any Endpoint, type: T.Type) async throws -> T where T : Decodable {
        <#code#>
    }
    
    private func createURL(from endpoint: Endpoint) -> URL? {
        guard var components = URLComponents(url: endpoint.baseURL, resolvingAgainstBaseURL: true) else {
            return nil
        }
        components.path += endpoint.path
        components.queryItems = endpoint.queryItems
        return components.url
    }
}
