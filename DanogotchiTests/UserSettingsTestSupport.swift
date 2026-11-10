import Foundation
@testable import Danogotchi

final class TestUserSettings: UserSettingsRepository {
    var currentThemeUrl: String?
    var isStudyReminderEnabled = true
    var appearanceMode: AppearanceMode = .system
    /// 파일명이 바뀐 직후, 구독자에게 알리기 전에 호출된다 — 저장 순서를 검사할 때 쓴다
    var willPublishFileName: ((String?) -> Void)?
    private let fileNames = AsyncBroadcaster<String?>()
    var currentThemeImageFileName: String? {
        didSet {
            willPublishFileName?(currentThemeImageFileName)
            fileNames.send(currentThemeImageFileName)
        }
    }
    var themeImageFileNameChanges: AsyncStream<String?> {
        fileNames.stream(current: { self.currentThemeImageFileName })
    }
}
