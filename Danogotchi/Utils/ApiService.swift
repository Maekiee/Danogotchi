import Foundation
import Alamofire

enum ApiService {
    
    // 이미지 검색
    static func searchPhoto<T: Decodable>(api: ApiRouter, type: T.Type, completion: @escaping(Result<T, Error>) -> Void) where T: Decodable {
        AF.request(
            api.endPoint,
            method: api.method,
            parameters: api.parameter
        ).responseString { res in
            dump(res)
        }
    }
}
