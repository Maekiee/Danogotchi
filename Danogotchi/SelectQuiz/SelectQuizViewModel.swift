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
        let decreaseButtonTap: Observable<Void>
        let increaseButtonTap: Observable<Void>
    }
    
    struct Output {
        let isSection: Driver<Bool>
        let sectionCount: Driver<Int>
    }
    
    func transform(input: Input) -> Output {
        let isSection = BehaviorRelay<Bool>(value: false)
        let sectionCount = BehaviorRelay<Int>(value: 10)
        
        input.toggleIsOn
            .bind(to: isSection)
            .disposed(by: disposeBag)
        
        // 감소 버튼
        input.decreaseButtonTap
            .withLatestFrom(sectionCount.asObservable())
            .map { max(10, $0 - 10) }
            .bind(to: sectionCount)
            .disposed(by: disposeBag)
        
        // 증가 버튼
        input.increaseButtonTap
            .withLatestFrom(sectionCount.asObservable())
            .map { min(50, $0 + 10) }
            .bind(to: sectionCount)
            .disposed(by: disposeBag)
        
        return Output(
            isSection: isSection.asDriver(),
            sectionCount: sectionCount.asDriver()
        )
    }
}

