import Combine
import Foundation

protocol SavePhotoThemeUseCase {
    /// 사진첩에서 고른 이미지를 선택 영역대로 배경 테마로 저장한다.
    /// 결과는 메인 스레드에서 방출한다 — 구독자가 곧바로 UI 상태를 갱신한다.
    func execute(imageData: Data, crop: PhotoThemeCrop) -> AnyPublisher<Void, Error>
}

final class DefaultSavePhotoThemeUseCase: SavePhotoThemeUseCase {
    private let themeImageRepository: ThemeImageRepository

    init(themeImageRepository: ThemeImageRepository) {
        self.themeImageRepository = themeImageRepository
    }

    func execute(imageData: Data, crop: PhotoThemeCrop) -> AnyPublisher<Void, Error> {
        // Deferred로 감싸 구독 시점에 저장이 시작되게 한다 — Future만 쓰면 생성 즉시 시작된다
        return Deferred { [themeImageRepository] in
            Future { promise in
                Task {
                    do {
                        try await themeImageRepository.replace(imageData: imageData, crop: crop)
                        promise(.success(()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
