import Combine
import OSLog
import PhotosUI
import SwiftUI

/// SwiftUI 화면이라 BaseViewModel(Rx transform)을 따르지 않는다.
/// Relay를 @Published로 옮기는 글루만 늘어나고 얻는 것이 없어 ObservableObject를 쓴다.
final class PhotoThemeViewModel: ObservableObject {
    private static let retryMessage = "잠시후 다시 시도해주세요"
    private static let unsupportedMessage = "지원하지 않는 이미지 형식이에요. 다른 사진을 선택해주세요"

    @Published var pickedItem: PhotosPickerItem?
    @Published var isPickerPresented = false
    @Published var alertMessage: String?
    @Published private(set) var previewImage: UIImage?
    /// 스크롤마다 바뀌므로 발행하지 않는다 — 확인 버튼 활성 상태가 바뀔 때만 화면 갱신
    private(set) var crop: PhotoThemeCrop?
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false

    /// 저장이 끝났다는 "사실"만 위로 올린다 — 어디로 갈지는 Coordinator가 정한다
    var onThemeSaved: (() -> Void)?

    var canConfirm: Bool { imageData != nil && crop != nil && !isSaving && !isLoading }
    let targetAspectRatio = UIScreen.main.nativeBounds.width / UIScreen.main.nativeBounds.height

    private var imageData: Data?
    /// 새 선택이 이전 로딩을 대체한다 — 재할당이 곧 취소다
    private var loadCancellable: AnyCancellable?
    private var saveCancellable: AnyCancellable?
    private let savePhotoThemeUseCase: SavePhotoThemeUseCase
    /// UIScreen은 메인 스레드 전용이라 로딩 중이 아니라 생성 시점에 읽어둔다
    private let previewPixelSize = Int(UIScreen.main.nativeBounds.height)

    init(savePhotoThemeUseCase: SavePhotoThemeUseCase) {
        self.savePhotoThemeUseCase = savePhotoThemeUseCase
    }

    func load(item: PhotosPickerItem?) {
        guard let item else { return }
        isLoading = true

        let maxPixelSize = previewPixelSize
        loadCancellable = Self.imageDataPublisher(for: item)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            // 디코딩을 메인에서 하면 큰 사진에서 프레임이 끊긴다
            .map { (data: $0, image: ImageDecoder.decode(data: $0, maxPixelSize: maxPixelSize)) }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    // 전송 실패(iCloud 원본 다운로드 등)만 여기로 온다 — 포맷 문제는 apply가 처리한다
                    if case .failure(let error) = completion { self?.fail(with: error) }
                },
                receiveValue: { [weak self] picked in
                    self?.apply(data: picked.data, image: picked.image)
                }
            )
    }

    /// 파이프라인이 백그라운드에서 디코딩을 끝낸 뒤 메인에서 호출한다.
    /// image가 nil이면 ImageIO가 읽지 못한 포맷이다 — "지정" 이후가 아니라 선택 직후에 거른다.
    /// PhotosPickerItem은 테스트에서 만들 수 없어 이 지점을 internal로 연다.
    func apply(data: Data, image: UIImage?) {
        crop = nil
        guard let image else {
            imageData = nil
            previewImage = nil
            fail(with: PhotoThemeError.unsupportedFormat)
            return
        }

        imageData = data
        previewImage = image
    }

    // 늦게 도착한 이전 이미지의 레이아웃 결과 제외 — 저장할 수 없는 영역은 선택을 비운다
    func updateCropRect(_ rect: CGRect, for image: UIImage) {
        guard !isSaving, !isLoading, previewImage === image else { return }
        let updated = PhotoThemeCrop(rect)
        guard updated != crop else { return }
        if (updated == nil) != (crop == nil) { objectWillChange.send() }
        crop = updated
    }

    /// isSaving을 구독 이전에 세워 중복 탭이 두 번째 저장을 시작하지 못하게 한다.
    func confirmSelection() {
        guard canConfirm, let imageData, let crop else { return }
        isSaving = true

        // UseCase가 메인 전달을 보장하므로 여기서 스케줄러를 갈아타지 않는다
        saveCancellable = savePhotoThemeUseCase.execute(imageData: imageData, crop: crop)
            .map { _ in Result<Void, Error>.success(()) }
            .catch { Just(Result<Void, Error>.failure($0)) }
            .sink { [weak self] result in
                guard let self else { return }
                self.isSaving = false

                switch result {
                case .success:
                    self.onThemeSaved?()
                case .failure(let error):
                    // 실패해도 선택은 남겨 같은 사진으로 바로 다시 시도할 수 있게 한다
                    self.fail(with: error)
                }
            }
    }

    /// iCloud 원본이면 여기서 네트워크 다운로드가 일어난다 — 수 초 걸리거나 실패할 수 있다
    private static func imageDataPublisher(for item: PhotosPickerItem) -> AnyPublisher<Data, Error> {
        return Deferred {
            Future { promise in
                item.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data?):
                        promise(.success(data))
                    case .success(nil):
                        promise(.failure(PhotoThemeError.transferFailed))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func fail(with error: Error) {
        AppLogger.ui.error("사진첩 테마 처리 실패: \(String(describing: error), privacy: .public)")
        CrashReporter.record(error)
        alertMessage = Self.message(for: error)
    }

    private static func message(for error: Error) -> String {
        // 포맷 문제는 재시도로 해결되지 않는다 — 다른 사진을 고르라고 알려준다
        if case PhotoThemeError.unsupportedFormat = error { return unsupportedMessage }
        return retryMessage
    }
}
