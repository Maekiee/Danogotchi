import Foundation
import Alamofire

enum ApiRouter {
    case searchPhoto(word: String, page: Int)
    case wordBook
    
    var endPoint: URL {
        switch self {
        case .searchPhoto(word: let word, page: let page):
            URL(string: Secret.unsplashBaseURL + Secret.photoSearchURL + "?query=\(word)&page=\(page)&per_page=20&order_by=relevant")!
        case .wordBook:
            URL(string: Secret.unsplashBaseURL + Secret.photoSearchURL)!
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var parameter: [String: String] {
        return ["client_id": Secret.unsplashAccessKey]
    }
}
