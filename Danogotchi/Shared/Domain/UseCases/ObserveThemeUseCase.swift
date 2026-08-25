import Foundation
import RxSwift

protocol ObserveThemeUseCase {
    /// 현재 배경 테마 URL과 이후 변경분을 방출한다.
    func execute() -> Observable<String?>
}

final class DefaultObserveThemeUseCase: ObserveThemeUseCase {
    private let userInfo: UserInfoProtocol

    init(userInfo: UserInfoProtocol) {
        self.userInfo = userInfo
    }

    func execute() -> Observable<String?> {
        // themeUrlObservable은 앱 시작 시 nil에서 출발하므로 저장된 값을 먼저 흘려준다
        return userInfo.themeUrlObservable
            .startWith(userInfo.currentThemeUrl)
    }
}
