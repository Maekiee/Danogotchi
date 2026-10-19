import Foundation
import OSLog

protocol ObserveThemeUseCase {
    /// 배경으로 쓸 로컬 이미지 파일 URL과 이후 변경분을 방출한다. 저장된 이미지가 없으면 nil.
    func execute() -> AsyncStream<URL?>
}

final class DefaultObserveThemeUseCase: ObserveThemeUseCase {
    private let themeImageRepository: ThemeImageRepository

    init(themeImageRepository: ThemeImageRepository) {
        self.themeImageRepository = themeImageRepository
    }

    func execute() -> AsyncStream<URL?> {
        // 감시를 먼저 등록한 뒤 복구한다 — 복구로 바뀐 파일도 감시에 잡힌다
        let images = themeImageRepository.storedImageChanged
        // 구독이 끝나도 복구는 끝까지 간다 — 다음 진입 때 바로 보인다
        Task { [themeImageRepository] in await Self.restoreIfNeeded(themeImageRepository) }
        return images
    }

    private static func restoreIfNeeded(_ themeImageRepository: ThemeImageRepository) async {
        guard themeImageRepository.storedImageFileURL() == nil,
              let rawUrl = themeImageRepository.lastSelectedRawUrl else { return }
        do {
            try await themeImageRepository.replace(rawUrl: rawUrl)
        } catch {
            AppLogger.network.error("테마 이미지 복구 실패: \(String(describing: error), privacy: .public)")
        }
    }
}
