import UIKit
import OSLog
import RxSwift

final class DefaultThemeImageRepository {
    /// 내려받을 포맷. 앞에서부터 시도하고, 실패하면 다음으로 넘어간다.
    private enum Format: String, CaseIterable {
        case heic
        case webp
    }

    private static let quality = 85

    private let apiClient: ApiClient
    private let storage: ImageFileStorage
    private let userInfo: UserInfoProtocol
    /// 화면 픽셀 크기. UIScreen은 메인 스레드 전용이라 다운로드 중이 아니라 생성 시점에 읽어둔다.
    private let targetPixelSize: CGSize

    init(
        apiClient: ApiClient,
        storage: ImageFileStorage,
        userInfo: UserInfoProtocol
    ) {
        self.apiClient = apiClient
        self.storage = storage
        self.userInfo = userInfo
        self.targetPixelSize = UIScreen.main.nativeBounds.size
    }
}

extension DefaultThemeImageRepository: ThemeImageRepository {
    var storedImageChanged: Observable<URL?> {
        return userInfo.themeImageFileNameObservable
            .map { [storage] fileName in
                guard let fileName else { return nil }
                return storage.existingFileURL(fileName: fileName)
            }
    }

    var lastSelectedRawUrl: String? {
        return userInfo.currentThemeUrl
    }

    func storedImageFileURL() -> URL? {
        guard let fileName = userInfo.currentThemeImageFileName else { return nil }
        return storage.existingFileURL(fileName: fileName)
    }

    func replace(rawUrl: String) -> Single<Result<Void, Error>> {
        return Single.create { observer in
            let task = Task { [self] in
                do {
                    try await performReplace(rawUrl: rawUrl)
                    observer(.success(.success(())))
                } catch {
                    observer(.success(.failure(error)))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }
}

private extension DefaultThemeImageRepository {
    /// 순서가 중요하다. 먼저 지우면 다운로드가 실패했을 때 기존 배경까지 잃는다.
    func performReplace(rawUrl: String) async throws {
        let (data, fileExtension) = try await fetchImageData(rawUrl: rawUrl)

        let fileName = UUID().uuidString + "." + fileExtension
        try storage.save(data, fileName: fileName)

        userInfo.currentThemeImageFileName = fileName
        userInfo.currentThemeUrl = rawUrl

        // 마지막에 정리한다. 여기서 실패하거나 직전에 앱이 죽어도 다음 저장 때 함께 치워진다.
        storage.removeAllExcept(fileName: fileName)
    }

    /// HEIC로 먼저 받고, 실패하면 WebP로 한 번 더 시도한다.
    /// 돌려주는 확장자는 요청한 포맷이 아니라 **실제로 받은 바이트의 타입**이다.
    func fetchImageData(rawUrl: String) async throws -> (Data, String) {
        var lastError: Error = NetworkError.invalidURL

        for format in Format.allCases {
            // 취소됐으면 다음 포맷을 시도하지 않는다
            try Task.checkCancellation()

            guard let url = makeImageURL(rawUrl: rawUrl, format: format) else {
                lastError = NetworkError.invalidURL
                continue
            }

            do {
                let data = try await apiClient.data(from: url)

                // 상태코드로는 판정할 수 없다 — CDN은 fm 값을 못 알아들어도 200에 다른 포맷을 준다
                guard let fileExtension = ImageDecoder.validate(data) else {
                    throw NetworkError.transport(URLError(.cannotDecodeContentData))
                }
                return (data, fileExtension)
            } catch {
                lastError = error
                AppLogger.network.error("테마 이미지 \(format.rawValue, privacy: .public) 내려받기 실패: \(String(describing: error), privacy: .public)")
            }
        }

        throw lastError
    }

    /// scaleAspectFill이 기기에서 하는 센터 크롭을 서버에서 미리 한다.
    /// 화면에 나오는 결과는 같고 용량과 디코딩 메모리만 줄어든다.
    ///
    /// urls.raw에는 이미 쿼리가 붙어 있으므로 `&`로 이어붙인다.
    /// urls.full은 fm=jpg를 이미 포함해 fm이 중복되므로 쓰지 않는다.
    private func makeImageURL(rawUrl: String, format: Format) -> URL? {
        let width = Int(targetPixelSize.width)
        let height = Int(targetPixelSize.height)
        let query = "&w=\(width)&h=\(height)&fit=crop&crop=center&fm=\(format.rawValue)&q=\(Self.quality)"
        return URL(string: rawUrl + query)
    }
}
