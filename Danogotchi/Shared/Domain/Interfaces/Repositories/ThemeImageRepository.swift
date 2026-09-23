import Foundation
import RxSwift

protocol ThemeImageRepository {
    /// 저장 파일이 바뀔 때마다 새 파일 URL을 방출한다. 파일이 없으면 nil.
    var storedImageChanged: Observable<URL?> { get }

    /// 마지막으로 고른 사진의 원본 URL. 로컬 파일이 사라졌을 때 복구에 쓴다.
    var lastSelectedRawUrl: String? { get }

    /// 선택한 사진을 화면 크기로 내려받아 로컬에 저장하고, 직전 파일을 지운다.
    func replace(rawUrl: String) -> Single<Result<Void, Error>>

    /// 사진첩에서 고른 이미지를 선택 영역대로 합성해 로컬에 저장하고, 직전 파일을 지운다.
    /// 네트워크가 없어 반응형 래핑 없이 처리한다 — nonisolated async라 호출자의 액터(메인)를 벗어나 실행된다.
    /// 원격 URL이 없으므로 lastSelectedRawUrl을 비워 재다운로드 복구 대상에서 제외한다.
    func replace(imageData: Data, crop: PhotoThemeCrop) async throws

    /// 현재 저장된 배경 이미지 파일 URL. 파일이 없으면 nil.
    func storedImageFileURL() -> URL?
}
