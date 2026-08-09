import Foundation
import Alamofire

enum ApiRouter {
    case searchPhoto(word: String, page: Int)

    var endPoint: URL? {
        switch self {
        case .searchPhoto(word: let word, page: let page):
            var components = URLComponents(string: Secret.unsplashBaseURL + Secret.photoSearchURL)
            components?.queryItems = [
                URLQueryItem(name: "query", value: word),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "20"),
                URLQueryItem(name: "order_by", value: "relevant")
            ]
            return components?.url
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var parameter: [String: String] {
        switch self {
        case .searchPhoto(word: _, page: _):
            let accessKey = Secret.unsplashKeys.randomElement()!
            return ["client_id": accessKey]
        }
    }
}
