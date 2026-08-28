import Foundation

enum UnsplashApiRouter: Endpoint {
    case searchPhoto(query: String, page: Int)
    
    var path: String {
        switch self {
        case .searchPhoto: return "/search/photos"
        }
    }
    
    var method: HTTPMethod { .get }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case let .searchPhoto(query, page):
            return [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "20"),
                URLQueryItem(name: "order_by", value: "relevant"),
            ]
        }
    }
}
