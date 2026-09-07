import Foundation

final class DefaultSearchThemeRepository {
    private let apiClient: ApiClient
    
    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
    
}

extension DefaultSearchThemeRepository: SearchThemeRepository {
    func searchPhotos(query: String, page: Int) async throws -> SearchPhotoEntity {
        let dto = try await apiClient.request(
            UnsplashApiRouter.searchPhoto(query: query, page: page),
            responseType: SearchPhotoDTO.self
        )

        return dto.toEntity()
    }
}
