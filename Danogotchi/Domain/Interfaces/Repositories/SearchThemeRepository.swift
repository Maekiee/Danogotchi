import Foundation
import RxSwift

protocol SearchThemeRepository {
    func searchPhotos(query: String, page: Int) -> Single<Result<SearchPhotoEntity, Error>>
}
