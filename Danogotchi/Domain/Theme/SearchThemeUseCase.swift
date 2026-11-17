import Foundation

protocol SearchThemeUseCase {
    func execute(query: String, page: Int) async throws -> SearchPhotoEntity
}

final class DefaultSearchThemeUseCase: SearchThemeUseCase {
    private let repository: SearchThemeRepository

    init(repository: SearchThemeRepository) {
        self.repository = repository
    }

    func execute(query: String, page: Int) async throws -> SearchPhotoEntity {
        return try await repository.searchPhotos(query: query, page: page)
    }
}
