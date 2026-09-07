import Foundation

protocol SearchThemeRepository {
    func searchPhotos(query: String, page: Int) async throws -> SearchPhotoEntity
}
