import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class BookListViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    private let activeManager = ActiveLearningManager.shared
    
    private let recommendBookRepo = RecommendBookRepository()
    private let wordBookRepo = WordBookRepository()
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let myBook: Driver<WordBook?>
        let recommendBooks: Driver<[WordBook]>
    }
    
    func transform(input: Input) -> Output {
        let myBookRelay = BehaviorRelay<WordBook?>(value: nil)
        let recommendBookRelay = BehaviorRelay<[WordBook]>(value: [])
        
        let viewWillAppear = input.viewWillAppear.take(1).share()
        
        viewWillAppear.bind(with: self) { owner, _ in
            // 1. 'activeBookIdentifier'가 아닌 'selectedBookId' (기본 Realm ID)를 사용
            if let wordBookId = owner.userInfo.selectedBookId,
               let bookId = try? ObjectId(string: wordBookId) {
                
                // 2. 단어장 객체(Object)를 가져옴
                if let bookObject = owner.wordBookRepo.read(id: bookId) {
                    // 3. ⭐️ 단어 목록(wordList)을 함께 로드 ⭐️
                    let words = owner.wordBookRepo.fetchWordsInWordBook(id: bookId)
                    
                    let book = WordBook(
                        id: bookObject.id.stringValue,
                        title: bookObject.title,
                        wordList: words, // ⭐️ 빈 배열 [] 대신 실제 'words' 주입 ⭐️
                        createAt: bookObject.createAt
                    )
                    myBookRelay.accept(book)
                } else {
                    // ID는 있으나 객체가 없는 경우 (삭제된 경우 등)
                    myBookRelay.accept(nil)
                }
            } else {
                // '기본 내 단어장'이 아예 설정되지 않은 경우
                myBookRelay.accept(nil)
            }
        }.disposed(by: disposeBag)
        
        
        
        // 추천 단어장 불러오기
        viewWillAppear.flatMapLatest {
            return self.recommendBookRepo.fetchRecommendBooks()
        }.bind(with: self) { owner, books in
            recommendBookRelay.accept(books)
            print("추천 단어장: >>> \(books)")
        }.disposed(by: disposeBag)
        
        
        return Output(
            myBook: myBookRelay.asDriver(),
            recommendBooks: recommendBookRelay.asDriver()
        )
    }
}
