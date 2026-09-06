import Foundation
import RxSwift

protocol ThemeImageRepository {
    /// 저장 파일이 바뀔 때마다 새 파일 URL을 방출한다. 파일이 없으면 nil.
    var storedImageChanged: Observable<URL?> { get }

    /// 마지막으로 고른 사진의 원본 URL. 로컬 파일이 사라졌을 때 복구에 쓴다.
    var lastSelectedRawUrl: String? { get }

    /// 선택한 사진을 화면 크기로 내려받아 로컬에 저장하고, 직전 파일을 지운다.
    func replace(rawUrl: String) -> Single<Result<Void, Error>>

    /// 현재 저장된 배경 이미지 파일 URL. 파일이 없으면 nil.
    func storedImageFileURL() -> URL?
}
