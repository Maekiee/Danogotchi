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
    
    // 번역 api
    static func searcMeaning<T: Decodable>(api: ApiRouter, type: T.Type) -> Single<Result<TranslatedDTO, Error>> {
        print("함수 실행")
        return Single.create { observer in
            print("통신 시작")
            AF.request(
                api.endPoint,
                method: api.method,
                parameters: api.parameter
            ).responseDecodable(of: TranslatedDTO.self) { res in
                print(res)
                switch res.result {
                case .success(let value):
                    print(value)
                    observer(.success(.success(value)))
                case .failure(let error):
                    print("네트워크 통신 에러: \(error)")
                }
            }
            
            return Disposables.create()
        }
        print("통신 끝")
    }
}
