import Foundation
import OSLog
import RxSwift

protocol ObserveThemeUseCase {
    /// 배경으로 쓸 로컬 이미지 파일 URL과 이후 변경분을 방출한다. 저장된 이미지가 없으면 nil.
    func execute() -> Observable<URL?>
}

final class DefaultObserveThemeUseCase: ObserveThemeUseCase {
    private let themeImageRepository: ThemeImageRepository

    init(themeImageRepository: ThemeImageRepository) {
        self.themeImageRepository = themeImageRepository
    }

    func execute() -> Observable<URL?> {
        return Observable.merge(
            themeImageRepository.storedImageChanged,
            restoreIfNeeded()
        )
    }

    private func restoreIfNeeded() -> Observable<URL?> {
        return Observable.deferred { [themeImageRepository] in
            guard themeImageRepository.storedImageFileURL() == nil,
                  let rawUrl = themeImageRepository.lastSelectedRawUrl else { return .empty() }

            return themeImageRepository.replace(rawUrl: rawUrl)
                .asObservable()
                .do(onNext: { result in
                    guard case .failure(let error) = result else { return }
                    AppLogger.network.error("테마 이미지 복구 실패: \(String(describing: error), privacy: .public)")
                })
                .flatMap { _ in Observable<URL?>.empty() }
        }
    }
}
