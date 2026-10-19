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
        let (stream, continuation) = AsyncStream.makeStream(of: URL?.self, bufferingPolicy: .bufferingNewest(1))
        let observe = Task {
            for await image in images { continuation.yield(image) }
            continuation.finish()
        }
        let restore = Task { [themeImageRepository] in
            await Self.restoreIfNeeded(themeImageRepository)
        }
        continuation.onTermination = { _ in
            observe.cancel()
            restore.cancel()
        }
        return stream
    }

    private static func restoreIfNeeded(_ themeImageRepository: ThemeImageRepository) async {
        guard themeImageRepository.storedImageFileURL() == nil,
              let rawUrl = themeImageRepository.lastSelectedRawUrl else { return }
        do {
            try await themeImageRepository.replace(rawUrl: rawUrl)
        } catch {
            // 구독이 끝나 취소된 복구는 실패로 남기지 않는다
            guard !Task.isCancelled else { return }
            AppLogger.network.error("테마 이미지 복구 실패: \(String(describing: error), privacy: .public)")
        }
    }
}
