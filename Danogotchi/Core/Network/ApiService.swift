import Foundation
import Alamofire
import RxSwift
import RxCocoa

enum ApiService {
    
    // 이미지 검색
    static func searchPhoto<T: Decodable>(api: ApiRouter, type: T.Type) -> Single<Result<SearchPhotoDTO, Error>> {
        return Single.create { observer in
            AF.request(
                api.endPoint,
                method: api.method,
                parameters: api.parameter
            ).responseDecodable(of: SearchPhotoDTO.self) { res in
                switch res.result {
                case .success(let value):
                    observer(.success(.success(value)))
                case .failure(let error):
                    print("네트워크 에러\(error)")
                }
            }
            
            return Disposables.create()
        }
    }
}
