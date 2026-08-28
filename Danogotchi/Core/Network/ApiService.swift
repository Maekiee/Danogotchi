import Foundation
import Alamofire
import RxSwift
import RxCocoa

enum ApiService {
    
    // 이미지 검색
//    static func searchPhoto<T: Decodable>(api: ApiRouter, type: T.Type) -> Single<Result<SearchPhotoDTO, Error>> {
//        return Single.create { observer in
//            guard let url = api.endPoint else {
//                observer(.success(.failure(URLError(.badURL))))
//                return Disposables.create()
//            }
//
//            // 에러는 스트림 에러가 아닌 값(Result.failure)으로 방출한다.
//            // observer(.failure:)로 던지면 상위 flatMapLatest 시퀀스가 종료돼 이후 검색이 죽는다.
//            let request = AF.request(
//                url,
//                method: api.method,
//                parameters: api.parameter
//            ).responseDecodable(of: SearchPhotoDTO.self) { res in
//                switch res.result {
//                case .success(let value):
//                    observer(.success(.success(value)))
//                case .failure(let error):
//                    observer(.success(.failure(error)))
//                }
//            }
//
//            return Disposables.create { request.cancel() }
//        }
//    }
}
