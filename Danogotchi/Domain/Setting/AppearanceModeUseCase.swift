import Foundation

protocol AppearanceModeUseCase {
    /// 저장된 화면 모드. 처음 실행은 시스템 설정을 따른다
    var current: AppearanceMode { get }
    /// 저장하고 앱 전체에 바로 적용한다
    func set(_ mode: AppearanceMode)
    /// 저장된 모드를 앱 전체에 적용한다 (앱 시작)
    func applySaved()
}

final class DefaultAppearanceModeUseCase: AppearanceModeUseCase {
    private let userSettings: UserSettingsRepository
    private let applier: AppearanceApplying

    init(userSettings: UserSettingsRepository, applier: AppearanceApplying) {
        self.userSettings = userSettings
        self.applier = applier
    }

    var current: AppearanceMode {
        return userSettings.appearanceMode
    }

    func set(_ mode: AppearanceMode) {
        userSettings.appearanceMode = mode
        applier.apply(mode)
    }

    func applySaved() {
        applier.apply(userSettings.appearanceMode)
    }
}
