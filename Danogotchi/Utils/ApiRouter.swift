import Foundation
import Alamofire

enum ApiRouter {
    case searchPhoto(word: String, page: Int)
    case translate(text: String)
    
    var endPoint: URL {
        switch self {
        case .searchPhoto(word: let word, page: let page):
            URL(string: Secret.unsplashBaseURL + Secret.photoSearchURL + "?query=\(word)&page=\(page)&per_page=20&order_by=relevant")!
        case .translate(_):
            URL(string: Secret.deeplBaseUrl + "v2/translate")!
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var header: HTTPHeaders {
        switch self {
        case .searchPhoto:
            return [:]
        case .translate(text: _):
            let accessKey = Secret.deeplApiKeys.randomElement()!
            return [
                "Authorization": "DeepL-Auth-Key \(accessKey)",
                "Content-Type": "application/json"
            ]
        }
    }
    
    var parameter: [String: String] {
        switch self {
        case .searchPhoto(word: _, page: _):
            let accessKey = Secret.unsplashKeys.randomElement()!
            return ["client_id": accessKey]
        case .translate(text: let text):
            return [
                "text": text,
                "target_lang":"KO"
            ]
        }
    }
}
