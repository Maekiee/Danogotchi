import Foundation
import RxSwift

protocol SearchThemeRepoProtocol {
    func searchPhotos(query: String, page: Int) -> Single<Result<SearchPhotoEntity, Error>>
}

final class SearchThemeRepository: SearchThemeRepoProtocol {
    func searchPhotos(query: String, page: Int) -> RxSwift.Single<Result<SearchPhotoEntity, Error>> {
        let api = ApiRouter.searchPhoto(word: query, page: page)
        
        return ApiService.searchPhoto(api: api, type: SearchPhotoDTO.self)
            .map { response in
                switch response {
                case .success(let dto):
                    let entity = dto.toEntity()
                    return .success(entity)
                case .failure(let error):
                    return .failure(error)
                }
            }
        
    }
    
    
}
