import Foundation
import RxSwift
import RxCocoa
import RealmSwift


final class ExploreVocabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    private let wordRepository: WordRepositoryProtocol
    private let learnHistoryRepository: LearningHistoryRepositoryProtocol
    
    init(
        wordRepository: WordRepositoryProtocol,
        learnHistoryRepository: LearningHistoryRepositoryProtocol
    ) {
        self.wordRepository = wordRepository
        self.learnHistoryRepository = learnHistoryRepository
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let selectedWordCard: Observable<Word> // 단어 삭제
    }
    
    struct Output {
        let wordItems: Driver<[WordDisplayInfo]>
    }
    
    func transform(input: Input) -> Output {
        let activeBookRelay = ActiveLearningManager.shared.activeBook
        let activeBookSourceRelay = ActiveLearningManager.shared.activeBookSource
        
        let allWordItems = BehaviorRelay<[WordDisplayInfo]>(value: [])
        
        let bookChangedTrigger = activeBookRelay.compactMap { $0 }.map { _ in () }
    
        let viewRefreshTrigger = input.viewWillAppear.startWith(())
        
        Observable.merge(bookChangedTrigger, viewRefreshTrigger)
            .withLatestFrom(activeBookRelay.compactMap { $0 })
            .bind(with: self) { owner, book in
                
                
                let wordList = book.wordList.reversed()
                
                let histories = owner.learnHistoryRepository.fetchAllHistory()
                let historiesByWord = Dictionary(grouping: histories, by: { $0.wordId })
                
                let historyStats = historiesByWord.mapValues { historyModels -> (correct: Int, total: Int) in
                    let correctCount = historyModels.filter { $0.isCorrect }.count
                    return (correct: correctCount, total: historyModels.count)
                }
                
                let displayItems = wordList.map { word -> WordDisplayInfo in
                    if let stats = historyStats[word.id] {
                        let accuracy = stats.total > 0 ? Double(stats.correct) / Double(stats.total) : 0.0
                        return WordDisplayInfo(word: word, learningCount: stats.total, accuracy: accuracy)
                    } else {
                        return WordDisplayInfo(word: word, learningCount: 0, accuracy: 0.0)
                    }
                }
                allWordItems.accept(Array(displayItems))
                
            }.disposed(by: disposeBag)
        
        return Output(
            wordItems: allWordItems.asDriver()
        )
    }
    

}
