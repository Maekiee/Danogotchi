import Foundation
import RxSwift
import RxCocoa
import RealmSwift


final class WordTabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    
    private let wordBookRepo: WordBookRepositoryProtocol
    private let wordRepo: WordRepositoryProtocol
    
    init(
        wordBookRepo: WordBookRepositoryProtocol = WordBookRepository(),
        wordRepo: WordRepositoryProtocol = WordRepository()) {
            self.wordBookRepo = wordBookRepo
            self.wordRepo = wordRepo
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let selectedWordCard: Observable<WordModel>
    }
    
    struct Output {
        let currentWordbook: Driver<Bool>
        let bookTitle: Driver<String>
        let wordItems: Driver<[WordModel]>
    }
    
    func transform(input: Input) -> Output {
        let hasLearningWordBook = BehaviorRelay(value: true)
        let bookTitle = BehaviorRelay<String>(value: "")
        let wordItems = BehaviorRelay<[WordModel]>(value: [])
        
        // viewDidLoad
        if let wordBookId = userInfo.selectedBookId,
           let bookId = try? ObjectId(string: wordBookId) {
            hasLearningWordBook.accept(false)
            
            // 단어장 타이틀
            if let wordBook = wordBookRepo.read(id: bookId) {
                bookTitle.accept(wordBook.title)
            }
            
            // 단어장 단어 리스트
            let wordList = wordBookRepo.fetchWordsInWordBook(id: bookId).reversed()
            wordItems.accept(Array(wordList))
            
            // 단어장 0개인지 아닌지 체크
        } else {
            print("유저 디볼트에 값이 없나요?")
            hasLearningWordBook.accept(true)
        }
        
        userInfo.selectedBookIdObservable
            .compactMap { $0 } // nil 제거
            .distinctUntilChanged() // 중복 이벤트 방지
            .bind(with: self) { owner, bookStrId in
                print("선택된 단어장 ID 변경됨: \(bookStrId)")
                // 여기서 필요한 동작 수행
                let allWordBook = owner.wordBookRepo.readAll()
                if allWordBook.isEmpty {
                    // 단어장 없는 경우
                    hasLearningWordBook.accept(true)
                } else {
                    // 단어장 있는 경우
                    guard let bookObjectId = try? ObjectId(string: bookStrId) else { return }
                    
                    // 단어장 타이틀 업데이트
                    if let wordBook = owner.wordBookRepo.read(id: bookObjectId) {
                        bookTitle.accept(wordBook.title)
                    }
//                    
//                    // 단어 리스트 업데이트
                    let wordList = owner.wordBookRepo.fetchWordsInWordBook(id: bookObjectId).reversed()
                    wordItems.accept(Array(wordList))
                    hasLearningWordBook.accept(false)
                }
            }.disposed(by: disposeBag)
        
        input.viewWillAppear
            .skip(1)
            .bind(with: self) { owner, _ in
                print("단어 장 업데이트")
                
                // 전체 단어장 불러오기
                let allWordBook = owner.wordBookRepo.readAll()
                if allWordBook.isEmpty {
                    // 단어장 없는 경우
                    hasLearningWordBook.accept(true)
                } else {
                    // 단어장 있는 경우
                    guard let bookId = owner.userInfo.selectedBookId else { return }
                    let bookObjectId = try! ObjectId(string: bookId)
                    
                    // 단어장 타이틀 업데이트
                    if let wordBook = owner.wordBookRepo.read(id: bookObjectId) {
                        bookTitle.accept(wordBook.title)
                    }
                    
                    // 단어 리스트 업데이트
                    let wordList = owner.wordBookRepo.fetchWordsInWordBook(id: bookObjectId).reversed()
                    wordItems.accept(Array(wordList))
                    hasLearningWordBook.accept(false)
                }
            }.disposed(by: disposeBag)
        
        input.selectedWordCard
            .bind(with: self) { owner, wordCard in
                // UI에서 지우기
                let filteredList = wordItems.value.filter { $0.id != wordCard.id }
                wordItems.accept(filteredList)
                
                // 디비에서 지우기
                let wordId = try! ObjectId(string: wordCard.id)
                owner.wordRepo.delete(id: wordId)
            }.disposed(by: disposeBag)
        
        
        return Output(
            currentWordbook: hasLearningWordBook.asDriver(),
            bookTitle: bookTitle.asDriver(onErrorJustReturn: ""),
            wordItems: wordItems.asDriver()
        )
    }
    

}
