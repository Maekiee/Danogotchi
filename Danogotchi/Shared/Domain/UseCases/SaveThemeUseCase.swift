import Foundation

protocol SaveThemeUseCase {
    /// 선택한 배경 테마 이미지 URL을 저장한다.
    func execute(url: String)
}

final class DefaultSaveThemeUseCase: SaveThemeUseCase {
    private let userInfo: UserInfoProtocol

    init(userInfo: UserInfoProtocol) {
        self.userInfo = userInfo
    }

    func execute(url: String) {
        userInfo.currentThemeUrl = url
    }
}
