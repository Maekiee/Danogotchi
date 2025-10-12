import Foundation
import RxSwift
import RxCocoa
import RealmSwift

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
        let selectedChangeBook: Observable<WordBook>
        let selectedDeleteTrigger: Observable<WordBook>
    }
    
    struct Output {
        let bookList: Driver<[WordBook]>
    }
    
    func transform(input: Input) -> Output {
        let bookList = BehaviorRelay<[WordBook]>(value: [])
        // 단어장 추가
        Observable.merge(
            input.viewWillAppear,
            input.refreshTrigger
        ).bind(with: self) { owner, _ in
            let bookItemList = owner.wordBookRepo.readAll().reversed()
            bookList.accept(Array(bookItemList))
        }.disposed(by: disposeBag)
        
        input.selectedChangeBook
            .distinctUntilChanged()
            .bind(with: self) { owner, book in
            }.disposed(by: disposeBag)
        
        // 단어장 삭제
        input.selectedDeleteTrigger
            .bind(with: self) { owner, bookInfo in
                let filteredList = bookList.value.filter { $0.id != bookInfo.id }
                bookList.accept(filteredList)
                
                // DB에서 지우기
                guard let bookObjectId = try? ObjectId(string: bookInfo.id) else { return }
                owner.wordBookRepo.delete(id: bookObjectId)
            }.disposed(by: disposeBag)
        
        
        return Output(
            bookList: bookList.asDriver()
        )
    }
}
