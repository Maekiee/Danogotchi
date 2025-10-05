import Foundation
import RxSwift
import RxCocoa


final class MyBookListViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    
    private let wordBookRepo: WordBookRepositoryProtocol
    private let wordRepo: WordRepositoryProtocol
    
    init(wordBookRepo: WordBookRepositoryProtocol = WordBookRepository(),
         wordRepo: WordRepositoryProtocol = WordRepository()) {
        self.wordBookRepo = wordBookRepo
        self.wordRepo = wordRepo
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let refreshTrigger: Observable<Void>
    }
    
    struct Output {
        let bookList: Driver<[WordBookModel]>
    }
    
    func transform(input: Input) -> Output {
        let bookList = BehaviorRelay<[WordBookModel]>(value: [])
        // 단어장 세트 리스트 불러오기
        
        
        // 단어 추가
        Observable.merge(
            input.viewWillAppear,
            input.refreshTrigger
        ).bind(with: self) { owner, _ in
            let bookItemList = owner.wordBookRepo.readAll().reversed()
            bookList.accept(Array(bookItemList))
        }.disposed(by: disposeBag)
        
        return Output(
            bookList: bookList.asDriver()
        )
    }
}
