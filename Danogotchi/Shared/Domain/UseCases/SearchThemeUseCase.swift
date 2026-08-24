import Foundation
import RxSwift

protocol SearchThemeUseCase {
    func execute(query: String, page: Int) -> Single<Result<SearchPhotoEntity, Error>>
}

final class DefaultSearchThemeUseCase: SearchThemeUseCase {
    private let repository: SearchThemeRepository

    init(repository: SearchThemeRepository) {
        self.repository = repository
    }

    func execute(query: String, page: Int) -> Single<Result<SearchPhotoEntity, Error>> {
        return repository.searchPhotos(query: query, page: page)
    }
}
