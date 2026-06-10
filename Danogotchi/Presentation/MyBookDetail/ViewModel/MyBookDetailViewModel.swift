import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class MyBookDetailViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    
    private let wordBookRepository: WordBookRepository
    private let wordRepository: WordRepository
    private let learningHistoryRepository: LearningHistoryRepository
    
    private let myBookObjectId = BehaviorRelay<ObjectId?>(value: nil)
    
    init(
        wordBookRepository: WordBookRepository,
        wordRepository: WordRepository,
        learningHistoryRepository: LearningHistoryRepository
    ) {
        self.wordBookRepository = wordBookRepository
        self.wordRepository = wordRepository
        self.learningHistoryRepository = learningHistoryRepository
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let deleteWordTrigger: Observable<Word>
    }
    
    struct Output {
        let wordList: Driver<[WordDisplayInfo]>
        let myBookObjectId: Observable<ObjectId?>
    }
    
    func transform(input: Input) -> Output {
        let wordList = BehaviorRelay<[WordDisplayInfo]>(value: [])
        
        input.viewWillAppear
            .bind(with: self) { owner, _ in
                
                guard let myBookStruct = owner.wordBookRepository.readAll().first(where: { $0.title == "나의 단어장" }) else {
                    // "나의 단어장"이 없는 경우 빈 배열 처리
                    wordList.accept([])
                    owner.myBookObjectId.accept(nil)
                    return
                }
                
                guard let bookId = try? ObjectId(string: myBookStruct.id) else {
                    wordList.accept([])
                    owner.myBookObjectId.accept(nil)
                    return
                }
                
                owner.myBookObjectId.accept(bookId)
                
                let myWordList = owner.wordBookRepository.fetchWordsInWordBook(id: bookId).reversed()
                let histories = owner.learningHistoryRepository.fetchAllHistory()
                let historiesByWord = Dictionary(grouping: histories, by: { $0.wordId })
                let historyStats = historiesByWord.mapValues { historyModels -> (correct: Int, total: Int) in
                    let correctCount = historyModels.filter { $0.isCorrect }.count
                    return (correct: correctCount, total: historyModels.count)
                }
                let displayItems = myWordList.map { word -> WordDisplayInfo in
                    if let stats = historyStats[word.id] {
                        let accuracy = stats.total > 0 ? Double(stats.correct) / Double(stats.total) : 0.0
                        return WordDisplayInfo(word: word, learningCount: stats.total, accuracy: accuracy)
                    } else {
                        return WordDisplayInfo(word: word, learningCount: 0, accuracy: 0.0)
                    }
                }
                wordList.accept(Array(displayItems))
                
            }.disposed(by: disposeBag)
        
        
        
        input.deleteWordTrigger
            .bind(with: self) { owner, wordItem in
                // UI에서 지우기
                let filteredList = wordList.value.filter { $0.word.id != wordItem.id }
                wordList.accept(filteredList)
                
                // 디비에서 지우기
                let wordId = try! ObjectId(string: wordItem.id)
                owner.wordRepository.delete(id: wordId)
                
                
                if let activeBookId = UserInfoManager.shared.activeBookIdentifier?.id,
                   let myBookId = owner.myBookObjectId.value?.stringValue {
                    
                    if activeBookId == myBookId {
                        UserInfoManager.shared.clearQuizState()
                    }
                }
            }.disposed(by: disposeBag)
        
        
        return Output(
            wordList: wordList.asDriver(),
            myBookObjectId: myBookObjectId.asObservable()
        )
    }
}
