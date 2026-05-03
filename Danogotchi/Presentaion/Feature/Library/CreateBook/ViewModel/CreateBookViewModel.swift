import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class CreateBookViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let wordBookRepository: WordBookRepositoryProtocol
    private let userInfo = UserInfoManager.shared
    
    init(
        wordBookRepository: WordBookRepositoryProtocol
    ) {
        self.wordBookRepository = wordBookRepository
    }
    
    
    struct Input {
        let selectedBookId: String?
        let textFieldValue: Observable<String>
        let createButtonTapped: Observable<Void>
    }
    
    struct Output {
        let createBookDoneTrigger: Signal<Void>
        let isCreateButtonEnabled: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let createBookDoneTrigger = PublishRelay<Void>()
        
        let isTitleValid = input.textFieldValue
            .map { (2..<10).contains($0.count) }
            .distinctUntilChanged()
            .share(replay: 1)
        
        input.createButtonTapped
            .withLatestFrom(input.textFieldValue)
            .bind(with: self) { owner, text in
                
                if let bookId = input.selectedBookId {
                    let bookObjectId = try! ObjectId(string: bookId)
                    owner.wordBookRepository.update(id: bookObjectId, title: text)
                    
                    createBookDoneTrigger.accept(())
                } else {
                    // 단어장 생성
                    owner.wordBookRepository.create(title: text)
                    // 생성한 단어장 가져오기
                    guard let newBook = owner.wordBookRepository.readAll().last else { return }

                    if owner.userInfo.selectedBookId == nil {
                        owner.userInfo.selectedBookId = newBook.id
                    }
                    
                    createBookDoneTrigger.accept(())
                }

                
            }.disposed(by: disposeBag)
        
        
        return Output(
            createBookDoneTrigger: createBookDoneTrigger.asSignal(),
            isCreateButtonEnabled: isTitleValid.asDriver(onErrorJustReturn: false)
        )
    }
}
