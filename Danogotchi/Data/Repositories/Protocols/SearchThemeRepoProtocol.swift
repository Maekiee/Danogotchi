import Foundation
import RxSwift

protocol SearchThemeRepoProtocol {
    func searchPhotos(query: String, page: Int) -> Single<Result<SearchPhotoEntity, Error>>
}
