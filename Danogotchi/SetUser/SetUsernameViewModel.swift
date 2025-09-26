import Foundation
import RxSwift
import RxCocoa



final class SetUsernameViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    
    struct Input {
        let usernameTextField: Observable<String>
        let confirmButtonTapped: Observable<Void>
    }
    
    struct Output {
        let usernameValidText: Driver<String>
    }
    
    func transform(input: Input) -> Output {
        let validStateText = input.usernameTextField
            .skip(2)
            .map { username in
                if !(2..<10).contains(username.count) {
                    return "2글자 이상 10글자 미만으로 설정해주세요"
                } else {
                    return "사용할 수 있는 닉네임 입니다."
                }
            }.asDriver(onErrorJustReturn: "")
        
        
        
        
        return Output(
            usernameValidText: validStateText
        )
    }
}
