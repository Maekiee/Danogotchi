import Foundation
import RxSwift
import RxCocoa

final class SelectQuizViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    
    private let bookRepo: WordBookRepositoryProtocol
    
    init(bookRepo: WordBookRepositoryProtocol = WordBookRepository()) {
        self.bookRepo = bookRepo
    }
    
    
    struct Input {
        let toggleIsOn: Observable<Bool>
    }
    
    struct Output {
        let isSection: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let isSection = BehaviorRelay<Bool>(value: false)
        
        input.toggleIsOn
            .bind(to: isSection)
            .disposed(by: disposeBag)
        
        return Output(
            isSection: isSection.asDriver()
        )
    }
}

