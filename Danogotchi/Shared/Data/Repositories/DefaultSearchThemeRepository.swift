import Foundation
import RxSwift

final class DefaultSearchThemeRepository {
    private let apiClient: ApiClient
    
    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
    
}

extension DefaultSearchThemeRepository: SearchThemeRepository {
    func searchPhotos(query: String, page: Int) -> Single<Result<SearchPhotoEntity, Error>> {
        return Single.create { [apiClient] observer in
            let task = Task {
                do {
                    let dto = try await apiClient.request(
                        UnsplashApiRouter.searchPhoto(query: query, page: page),
                        responseType: SearchPhotoDTO.self
                    )
                    
                    observer(.success(.success(dto.toEntity())))
                } catch {
                    observer(.success(.failure(error)))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }
}
