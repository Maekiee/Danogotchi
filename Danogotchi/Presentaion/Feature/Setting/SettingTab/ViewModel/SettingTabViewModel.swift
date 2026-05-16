import Foundation
import RxSwift
import RxCocoa

final class SettingTabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let appEnv: AppEnvProvider
    private let appVersionRelay: BehaviorRelay<String>
    
    typealias SettingSection = (category: SettingMenu.Category, items: [SettingMenu])
    
    init(appEnv: AppEnvProvider) {
        self.appEnv = appEnv
        self.appVersionRelay = BehaviorRelay(value: appEnv.appVersionDisplay)
    }
    
    struct Input {
        let viewDidLoad: Observable<Void>
    }
    
    struct Output {
        let sections: Driver<[SettingSection]>
        let appVersion: Driver<String>
    }
    
    func transform(input: Input) -> Output {
        let sections = input.viewDidLoad
            .map { _ in
                SettingMenu.Category.allCases.map { (category: $0, items: $0.list) }
            }.asDriver(onErrorJustReturn: [])
        
        let appVersion = appVersionRelay.asDriver()
        
        return Output(
            sections: sections,
            appVersion: appVersion
        )
    }
}
