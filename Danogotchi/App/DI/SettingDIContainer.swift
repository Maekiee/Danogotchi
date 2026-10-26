import Foundation

final class SettingDIContainer {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    /// 문의 메일 전송 실패 보고용
    var reportError: @Sendable (Error) -> Void { dependencies.reportError }

    /// 사진 테마 미리보기 비율 — 저장 비율과 같은 출처
    var screenAspectRatio: CGFloat { dependencies.screenPixelSize.width / dependencies.screenPixelSize.height }

    func makeSettingTabViewModel() -> SettingTabViewModel {
        return SettingTabViewModel(
            appEnv: DefaultAppEnvProvider(),
            studyReminderUseCase: dependencies.makeStudyReminderUseCase(),
            appearanceModeUseCase: dependencies.makeAppearanceModeUseCase()
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
