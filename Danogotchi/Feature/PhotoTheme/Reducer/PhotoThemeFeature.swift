import Combine
import ComposableArchitecture
import OSLog
import PhotosUI
import SwiftUI
import UIKit

@Reducer
struct PhotoThemeFeature {
    private static let retryMessage = "잠시후 다시 시도해주세요"
    private static let unsupportedMessage = "지원하지 않는 이미지 형식이에요. 다른 사진을 선택해주세요"

    @ObservableState
    struct State: Equatable {
        var pickedItem: PhotosPickerItem?
        var isPickerPresented = false
        var alertMessage: String?
        var previewImage: UIImage?
        var imageData: Data?
        var isLoading = false
        var isSaving = false
        /// 스크롤마다 바뀐다 — 화면은 읽지 않고 저장에만 쓴다
        var crop: PhotoThemeCrop?
        /// 확인 버튼 활성 상태가 바뀔 때만 화면 갱신 — Equatable 필드는 같은 값 대입 시 알리지 않는다
        var hasCrop = false

        var canConfirm: Bool { imageData != nil && hasCrop && !isSaving && !isLoading }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case imageLoaded(data: Data, image: UIImage?)
        case imageLoadFailed(Error)
        case cropChanged(CGRect, UIImage)
        case confirmTapped
        case saveResponse(Result<Void, Error>)
    }

    enum CancelID { case load }

    let savePhotoThemeUseCase: SavePhotoThemeUseCase
    /// 저장이 끝났다는 "사실"만 위로 올린다 — 어디로 갈지는 Coordinator가 정한다
    let onThemeSaved: @MainActor @Sendable () -> Void
    /// UIScreen은 메인 스레드 전용이라 로딩 중이 아니라 생성 시점에 읽어둔다
    let previewPixelSize = Int(UIScreen.main.nativeBounds.height)

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.pickedItem):
                guard let item = state.pickedItem else { return .none }
                state.isLoading = true

                let maxPixelSize = previewPixelSize
                return .run { send in
                    // iCloud 원본이면 여기서 네트워크 다운로드가 일어난다 — 수 초 걸리거나 실패할 수 있다
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        throw PhotoThemeError.transferFailed
                    }
                    // run은 메인 밖에서 실행된다 — 디코딩을 메인에서 하면 큰 사진에서 프레임이 끊긴다
                    let image = ImageDecoder.decode(data: data, maxPixelSize: maxPixelSize)
                    await send(.imageLoaded(data: data, image: image))
                } catch: { error, send in
                    await send(.imageLoadFailed(error))
                }
                // 새 선택이 이전 로딩을 대체한다
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case .binding:
                return .none

            // image가 nil이면 ImageIO가 읽지 못한 포맷이다 — "지정" 이후가 아니라 선택 직후에 거른다
            case let .imageLoaded(data, image):
                state.isLoading = false
                state.crop = nil
                state.hasCrop = false
                guard let image else {
                    state.imageData = nil
                    state.previewImage = nil
                    Self.fail(&state, with: PhotoThemeError.unsupportedFormat)
                    return .none
                }

                state.imageData = data
                state.previewImage = image
                return .none

            // 전송 실패(iCloud 원본 다운로드 등)만 여기로 온다 — 포맷 문제는 imageLoaded가 처리한다
            case let .imageLoadFailed(error):
                state.isLoading = false
                Self.fail(&state, with: error)
                return .none

            // 늦게 도착한 이전 이미지의 레이아웃 결과 제외 — 저장할 수 없는 영역은 선택을 비운다
            case let .cropChanged(rect, image):
                guard !state.isSaving, !state.isLoading, state.previewImage === image else { return .none }
                state.crop = PhotoThemeCrop(rect)
                state.hasCrop = state.crop != nil
                return .none

            // isSaving을 구독 이전에 세워 중복 탭이 두 번째 저장을 시작하지 못하게 한다
            case .confirmTapped:
                guard state.canConfirm, let imageData = state.imageData, let crop = state.crop else { return .none }
                state.isSaving = true

                // UseCase가 메인 전달을 보장하므로 스케줄러를 갈아타지 않는다
                return .publisher {
                    savePhotoThemeUseCase.execute(imageData: imageData, crop: crop)
                        .map { _ in Action.saveResponse(.success(())) }
                        .catch { Just(Action.saveResponse(.failure($0))) }
                }

            case .saveResponse(.success):
                state.isSaving = false
                return .run { _ in await onThemeSaved() }

            // 실패해도 선택은 남겨 같은 사진으로 바로 다시 시도할 수 있게 한다
            case let .saveResponse(.failure(error)):
                state.isSaving = false
                Self.fail(&state, with: error)
                return .none
            }
        }
    }

    private static func fail(_ state: inout State, with error: Error) {
        AppLogger.ui.error("사진첩 테마 처리 실패: \(String(describing: error), privacy: .public)")
        CrashReporter.record(error)
        state.alertMessage = message(for: error)
    }

    private static func message(for error: Error) -> String {
        // 포맷 문제는 재시도로 해결되지 않는다 — 다른 사진을 고르라고 알려준다
        if case PhotoThemeError.unsupportedFormat = error { return unsupportedMessage }
        return retryMessage
    }
}
