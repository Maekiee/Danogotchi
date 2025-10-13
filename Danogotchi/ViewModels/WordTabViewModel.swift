import Foundation
import RxSwift
import RxCocoa
import RealmSwift


final class WordTabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    
    private let wordBookRepo: WordBookRepositoryProtocol
    private let wordRepo: WordRepositoryProtocol
    private let learningHistoryRepo: LearningHistoryRepositoryProtocol
    
    init(
        wordBookRepo: WordBookRepositoryProtocol = WordBookRepository(),
        wordRepo: WordRepositoryProtocol = WordRepository(),
        learningHistoryRepo: LearningHistoryRepositoryProtocol = LearningHistoryRepository()
    ) {
        self.wordBookRepo = wordBookRepo
        self.wordRepo = wordRepo
        self.learningHistoryRepo = learningHistoryRepo
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let selectedWordCard: Observable<Word>
    }
    
    struct Output {
        let currentWordbook: Driver<Bool>
        let bookTitle: Driver<String>
        let wordItems: Driver<[WordDisplayInfo]>
    }
    
    func transform(input: Input) -> Output {
        let hasLearningWordBook = BehaviorRelay<Bool>(value: true)
        let bookTitle = BehaviorRelay<String>(value: "")
        let wordItems = BehaviorRelay<[WordDisplayInfo]>(value: [])
        
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
            
            let histories = learningHistoryRepo.fetchAllHistory()
            let learningCounts = Dictionary(grouping: histories, by: { $0.wordId }).mapValues { $0.count }
            let displayItems = wordList.map { word -> WordDisplayInfo in
                let count = learningCounts[word.id] ?? 0
                return WordDisplayInfo(word: word, learningCount: count)
            }
            
            wordItems.accept(Array(displayItems))
            
        } else {
            print("유저 디볼트에 값이 없나요?")
            hasLearningWordBook.accept(true)
        }
        
        userInfo.selectedBookIdObservable
            .compactMap { $0 } // nil 제거
            .distinctUntilChanged() // 중복 이벤트 방지
            .bind(with: self) { owner, bookStrId in
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
                    
//                    // 단어 리스트 업데이트
                    let wordList = owner.wordBookRepo.fetchWordsInWordBook(id: bookObjectId).reversed()
                   
                    hasLearningWordBook.accept(false)
                    
                    let histories = owner.learningHistoryRepo.fetchAllHistory()
                    let learningCounts = Dictionary(grouping: histories, by: { $0.wordId }).mapValues { $0.count }
                    let displayItems = wordList.map { word -> WordDisplayInfo in
                        let count = learningCounts[word.id] ?? 0
                        return WordDisplayInfo(word: word, learningCount: count)
                    }
                    
                    wordItems.accept(Array(displayItems))
                    
                }
            }.disposed(by: disposeBag)
        
        input.viewWillAppear
            .skip(1)
            .bind(with: self) { owner, _ in
                print("WordTab 뷰윌 어피어")
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
                    
                    
                    let histories = owner.learningHistoryRepo.fetchAllHistory()
                    let learningCounts = Dictionary(grouping: histories, by: { $0.wordId }).mapValues { $0.count }
                    let displayItems = wordList.map { word -> WordDisplayInfo in
                        let count = learningCounts[word.id] ?? 0
                        return WordDisplayInfo(word: word, learningCount: count)
                    }
                    
                    
                    wordItems.accept(Array(displayItems))
                    hasLearningWordBook.accept(false)
                }
            }.disposed(by: disposeBag)
        
        input.selectedWordCard
            .bind(with: self) { owner, wordCard in
                // UI에서 지우기
                let filteredList = wordItems.value.filter { $0.word.id != wordCard.id }
                wordItems.accept(filteredList)
                
                // 디비에서 지우기
                let wordId = try! ObjectId(string: wordCard.id)
                owner.wordRepo.delete(id: wordId)
                
                owner.userInfo.clearQuizState()
            }.disposed(by: disposeBag)
        
        
        return Output(
            currentWordbook: hasLearningWordBook.asDriver(),
            bookTitle: bookTitle.asDriver(onErrorJustReturn: ""),
            wordItems: wordItems.asDriver()
        )
    }
    

}
