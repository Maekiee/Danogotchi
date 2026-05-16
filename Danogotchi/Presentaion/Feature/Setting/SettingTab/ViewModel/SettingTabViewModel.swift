import Foundation
import RxSwift
import RxCocoa

final class SettingTabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let appEnv: AppEnvProvider
    
    typealias SettingSection = (category: SettingMenu.Category, items: [SettingMenu])
    
    init(appEnv: AppEnvProvider) {
        self.appEnv = appEnv
    }
    
    struct Input { }
    
    struct Output {
        let sections: Driver<[SettingSection]>
        let appVersion: Driver<String>
    }
    
    func transform(input: Input) -> Output {
        let sections = Driver.just(
            SettingMenu.Category.allCases.map {
                (category: $0, items: $0.list)
            }
        )
        let appVersion = Driver.just(appEnv.appVersionDisplay)
        
        return Output(
            sections: sections,
            appVersion: appVersion
        )
    }
}
