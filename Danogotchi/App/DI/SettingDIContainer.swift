import Foundation

final class SettingDIContainer {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    /// 문의 메일 전송 실패 보고용
    var reportError: @Sendable (Error) -> Void { dependencies.reportError }

    func makeSettingTabViewModel() -> SettingTabViewModel {
        return SettingTabViewModel(
            appEnv: DefaultAppEnvProvider(),
            studyReminderUseCase: dependencies.makeStudyReminderUseCase()
        )
    }

    func makeSearchThemeViewModel() -> SearchThemeViewModel {
        return dependencies.makeSearchThemeViewModel()
    }

    func makePhotoThemeFeature(
        onThemeSaved: @escaping @MainActor @Sendable () -> Void,
        onClose: @escaping @MainActor @Sendable () -> Void = {}
    ) -> PhotoThemeFeature {
        return dependencies.makePhotoThemeFeature(onThemeSaved: onThemeSaved, onClose: onClose)
    }
}
