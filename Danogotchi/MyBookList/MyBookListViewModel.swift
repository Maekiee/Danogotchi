import Foundation
import RxSwift
import RxCocoa


final class MyBookListViewModel: BaseViewModel {
    private let dispose = DisposeBag()
    private let userInfo = UserInfoManager.shared
    
    private let wordBookRepo: WordBookRepositoryProtocol
    private let wordRepo: WordRepositoryProtocol
    
    init(wordBookRepo: WordBookRepositoryProtocol = WordBookRepository(),
         wordRepo: WordRepositoryProtocol = WordRepository()) {
        self.wordBookRepo = wordBookRepo
        self.wordRepo = wordRepo
    }
    
    struct Input {
        
    }
    
    struct Output {
        let bookList: Driver<[WordBookModel]>
    }
    
    func transform(input: Input) -> Output {
        let bookList = BehaviorRelay<[WordBookModel]>(value: [])
        // 단어장 세트 리스트 불러오기
        let bookItemList = wordBookRepo.readAll().reversed()
        bookList.accept(Array(bookItemList))
//        dump(bookList)
        
        return Output(
            bookList: bookList.asDriver()
        )
    }
}
