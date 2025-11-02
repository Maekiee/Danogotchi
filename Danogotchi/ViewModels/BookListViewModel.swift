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
    private let wordRepo = WordRepository()
    
    let downloadBookTrigger = PublishRelay<WordBook>()
    
    enum RecommendItem: Hashable {
        case downloaded(WordBook) // Realm에 복사된 단어장 (Realm 데이터)
        case notDownloaded(WordBook) // 아직 복사되지 않은 단어장 (Mock 데이터)
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let myBook: Driver<WordBook?>
        let recommendItems: Driver<[RecommendItem]>
        let downloadComplete: Signal<Void>
    }
    
    func transform(input: Input) -> Output {
        let myBookRelay = BehaviorRelay<WordBook?>(value: nil)
        let recommendItemsRelay = BehaviorRelay<[RecommendItem]>(value: [])
        let downloadCompleteRelay = PublishRelay<Void>()
        
        let refreshTrigger = Observable.merge(
            input.viewWillAppear.map { _ in () }, // .take(1) 제거하여 화면 진입 시마다 갱신
            downloadCompleteRelay.asObservable()
        ).startWith(())
        
        refreshTrigger.bind(with: self) { owner, _ in
            // 1. 'activeBookIdentifier'가 아닌 'selectedBookId' (기본 Realm ID)를 사용
            if let wordBookId = owner.userInfo.selectedBookId,
               let bookId = try? ObjectId(string: wordBookId) {
            
                if let bookObject = owner.wordBookRepo.read(id: bookId) {
                    let words = owner.wordBookRepo.fetchWordsInWordBook(id: bookId)
                    
                    let book = WordBook(
                        id: bookObject.id.stringValue,
                        title: bookObject.title,
                        wordList: words,
                        createAt: bookObject.createAt
                    )
                    myBookRelay.accept(book)
                } else {
                    myBookRelay.accept(nil)
                }
            } else {
                myBookRelay.accept(nil)
            }
        }.disposed(by: disposeBag)
        
        
        
        // 추천 단어장 불러오기
        refreshTrigger
            .flatMapLatest { [weak self] _ -> Observable<[RecommendItem]> in
                guard let self = self else { return .just([]) }
                let myBooks = self.wordBookRepo.readAll()
                
                // 2. Mock 추천 단어장 목록을 가져옴
                return self.recommendBookRepo.fetchRecommendBooks()
                    .map { mockBooks in
                        // 3. Mock 단어장 목록을 순회하며 Realm 목록과 비교
                        mockBooks.map { mockBook in
                            // Realm에 Mock 단어장과 "제목"이 같은 단어장이 있는지 확인
                            if let matchingRealmBook = myBooks.first(where: { $0.title == mockBook.title }) {
                                // 4. 있으면 .downloaded 상태 (Realm 데이터 전달)
                                return .downloaded(matchingRealmBook)
                            } else {
                                // 5. 없으면 .notDownloaded 상태 (Mock 데이터 전달)
                                return .notDownloaded(mockBook)
                            }
                        }
                    }
            }.bind(to: recommendItemsRelay) // 결과를 recommendItemsRelay에 바인딩
            .disposed(by: disposeBag)
        
        
        // 💡 12. 단어장 복사(다운로드) 로직
        downloadBookTrigger
            .bind(with: self) { owner, bookToCopy in
                
                // (방어 코드) 이미 Realm에 있는지 다시 한번 확인
                let allMyBooks = owner.wordBookRepo.readAll()
                if allMyBooks.contains(where: { $0.title == bookToCopy.title }) {
                    ToastManager.shared.show("이미 '내 단어장'에 존재합니다.")
                    downloadCompleteRelay.accept(()) // UI 새로고침
                    return
                }
                
                // 1. Realm에 새 단어장(WordBookObject) 생성
                owner.wordBookRepo.create(title: bookToCopy.title)
                
                // 2. 방금 생성한 단어장 객체를 Realm에서 다시 가져옴
                guard let newBookObject = owner.wordBookRepo.readAll().last(where: { $0.title == bookToCopy.title })?.toObject() else {
                    return // 생성 실패 시 중단
                }
                
                // 3. 추천 단어장의 단어 목록(Word)을 Realm 단어(WordObject)로 복사
                for word in bookToCopy.wordList {
                    // 3-1. 새 단어(WordObject) 생성
                    let newWordObject = owner.wordRepo.create(
                        thumbnail: "", // 썸네일은 비워둠
                        word: word.word,
                        meaning: word.meaning
                    )
                    // 3-2. 생성된 단어를 2번에서 만든 새 단어장에 연결
                    owner.wordBookRepo.addWord(bookId: newBookObject.id, word: newWordObject)
                }
                
                ToastManager.shared.show("'\(bookToCopy.title)' 단어장이 추가되었습니다.")
                downloadCompleteRelay.accept(()) // 4. UI 새로고침 신호
                
            }.disposed(by: disposeBag)
        
        
        return Output(
            myBook: myBookRelay.asDriver(),
            recommendItems: recommendItemsRelay.asDriver(), // 💡 13. 변경된 Relay 반환
            downloadComplete: downloadCompleteRelay.asSignal()
        )
    }
}
