import Foundation

protocol SaveThemeUseCase {
    /// 선택한 배경 테마 이미지를 로컬에 내려받아 저장한다.
    func execute(rawUrl: String) async throws
}

final class DefaultSaveThemeUseCase: SaveThemeUseCase {
    private let themeImageRepository: ThemeImageRepository

    init(themeImageRepository: ThemeImageRepository) {
        self.themeImageRepository = themeImageRepository
    }

    func execute(rawUrl: String) async throws {
        try await themeImageRepository.replace(rawUrl: rawUrl)
    }
}
