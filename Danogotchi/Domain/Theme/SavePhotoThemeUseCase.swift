import Foundation

protocol SavePhotoThemeUseCase {
    /// 사진첩에서 고른 이미지를 선택 영역대로 배경 테마로 저장한다.
    func execute(imageData: Data, crop: PhotoThemeCrop) async throws
}

final class DefaultSavePhotoThemeUseCase: SavePhotoThemeUseCase {
    private let themeImageRepository: ThemeImageRepository

    init(themeImageRepository: ThemeImageRepository) {
        self.themeImageRepository = themeImageRepository
    }

    func execute(imageData: Data, crop: PhotoThemeCrop) async throws {
        try await themeImageRepository.replace(imageData: imageData, crop: crop)
    }
}
