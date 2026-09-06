import Foundation
import RxSwift

protocol UserInfoProtocol: AnyObject {
    var username: String? { get set }
    var userId: String? { get set }
    /// 선택한 원본 사진의 URL. 온보딩 완료 판별과, 로컬 파일이 사라졌을 때의 복구에 쓴다.
    var currentThemeUrl: String? { get set }
    /// 로컬에 저장된 배경 이미지 파일명. 앱 컨테이너 경로는 재설치·복원 시 바뀌므로 파일명만 보관한다.
    var currentThemeImageFileName: String? { get set }
    var isStudyReminderEnabled: Bool { get set }
    var themeImageFileNameObservable: Observable<String?> { get }
}
