import Foundation
import RxSwift
import RxCocoa



final class SetUsernameViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userManager = UserInfoManager.shared
    
    struct Input {
        let usernameTextField: Observable<String>
        let confirmButtonTapped: Observable<Void>
    }
    
    struct Output {
        let usernameValidText: Driver<String>
        let buttonAbleState: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let validStateText = PublishRelay<String>()
        let buttonAbleState = BehaviorRelay<Bool>(value: false)
        var nickname = ""
        
        input.usernameTextField
            .skip(2)
            .do { text in
                nickname = text
            }
            .map { !(2..<10).contains($0.count) }
            .bind(with: self) { owner, isValid in
                buttonAbleState.accept(!isValid)
                validStateText.accept(isValid ? "2글자 이상 10글자 미만으로 설정해주세요" : "")
            }
            .disposed(by: disposeBag)
        
        input.confirmButtonTapped
            .bind(with: self) { owner, _ in
                // 유저 이름 저장
                owner.userManager.username = nickname
                
                // 코디네이터로 대체
//                CoordinatorTest.switchToMainVieWController()
            }.disposed(by: disposeBag)
                
        return Output(
            usernameValidText: validStateText.asDriver(onErrorJustReturn: ""),
            buttonAbleState: buttonAbleState.asDriver(onErrorJustReturn: false)
        )
    }
}
