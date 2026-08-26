import Foundation
import RxSwift
import RxCocoa

final class SettingTabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let appEnv: AppEnvProvider
    private let studyReminderUseCase: StudyReminderUseCase
    
    typealias SettingSection = (category: SettingMenu.Category, items: [SettingMenu])
    
    init(appEnv: AppEnvProvider, studyReminderUseCase: StudyReminderUseCase) {
        self.appEnv = appEnv
        self.studyReminderUseCase = studyReminderUseCase
    }
    
    struct Input {
        let itemSelected: Observable<SettingMenu>
        let reminderToggled: Observable<Bool>
    }
    
    struct Output {
        let sections: Driver<[SettingSection]>
        let appVersion: Driver<String>
        let isReminderOn: Driver<Bool>
        let action: Signal<SettingMenu.Action>
        let mailBody: Signal<String>
    }
    
    func transform(input: Input) -> Output {
        let sections = Driver.just(
            SettingMenu.Category.allCases.map {
                (category: $0, items: $0.list)
            }
        )
        let appVersion = Driver.just(appEnv.appVersionDisplay)
        let isReminderOn = Driver.just(studyReminderUseCase.isEnabled)
        let actionRelay = PublishRelay<SettingMenu.Action>()
        let mailBodyRelay = PublishRelay<String>()
        
        input.itemSelected
            .map { $0.action }
            .bind(to: actionRelay)
            .disposed(by: disposeBag)
        
        input.reminderToggled
            .bind(with: self) { owner, isOn in
                owner.studyReminderUseCase.setEnabled(isOn)
            }
            .disposed(by: disposeBag)

        input.itemSelected
            .filter { $0.action == .inquiry }
            .compactMap { [weak self] _ in self?.makeMailBody() }
            .bind(to: mailBodyRelay)
            .disposed(by: disposeBag)
        
        return Output(
            sections: sections,
            appVersion: appVersion,
            isReminderOn: isReminderOn,
            action: actionRelay.asSignal(),
            mailBody: mailBodyRelay.asSignal()
        )
    }
}

extension SettingTabViewModel {
    private func makeMailBody() -> String {
        return  """
                    궁금하신 점이나 불편 사항을 편하게 남겨주세요.
                    
                    
                    
                    
                    -------------------
                    앱 버전: \(appEnv.appVersionDisplay)
                    기기: \(appEnv.deviceModel)
                    OS 버전: \(appEnv.systemVersion)
                    -------------------
                    """
    }
}
