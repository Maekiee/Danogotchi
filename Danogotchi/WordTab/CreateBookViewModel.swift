import Foundation
import RxSwift
import RxCocoa

final class CreateBookViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let wordBookRepo: WordBookRepositoryProtocol
    private let userInfo = UserInfoManager.shared
    
    init(
        wordBookRepo: WordBookRepositoryProtocol = WordBookRepository()
    ) {
        self.wordBookRepo = wordBookRepo
    }
    
    
    struct Input {
        let textFieldValue: Observable<String>
        let createButtonTapped: Observable<Void>
    }
    
    struct Output {
        let createBookDoneTrigger: Signal<Void>
    }
    
    func transform(input: Input) -> Output {
        let createBookDoneTrigger = PublishRelay<Void>()
        
        input.createButtonTapped
            .withLatestFrom(input.textFieldValue)
            .bind(with: self) { owner, text in
                // 단어장 생성
                owner.wordBookRepo.create(title: text)
                // 생성한 단어장 가져오기
                guard let newBook = owner.wordBookRepo.readAll().last else { return }

                // UserInfoManager의 selectedBookId값이 nil 이면  newBook의 아이디 값 UserInfoManager의 selectedBookId로 값 전달
                if owner.userInfo.selectedBookId == nil {
                    owner.userInfo.selectedBookId = newBook.id
                }
                
                createBookDoneTrigger.accept(())
                // UserInfoManagerdml selectedBookId값이 nil이 아니면 아무런 동작 하지 않음
                
            }.disposed(by: disposeBag)
        
        
        return Output(
            createBookDoneTrigger: createBookDoneTrigger.asSignal()
        )
    }
}
