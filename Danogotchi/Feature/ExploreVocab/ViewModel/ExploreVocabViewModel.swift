import Foundation
import RxSwift
import RxCocoa


final class ExploreVocabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let vocabBookRepository: VocabBookRepository
    private let learnHistoryRepository: LearningHistoryRepository

    init(
        vocabBookRepository: VocabBookRepository,
        learnHistoryRepository: LearningHistoryRepository
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.learnHistoryRepository = learnHistoryRepository
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let wordItems: Driver<[VocabDisplayInfo]>
    }
    
    func transform(input: Input) -> Output {
        let allWordItems = BehaviorRelay<[VocabDisplayInfo]>(value: [])

        let bookChangedTrigger = vocabBookRepository.activeBookId.map { _ in () }

        let viewRefreshTrigger = input.viewWillAppear.startWith(())

        // 트리거마다 CoreData에서 다시 읽는다 — 단어 추가/삭제가 즉시 반영되도록
        Observable.merge(bookChangedTrigger, viewRefreshTrigger)
            .compactMap { [weak self] _ in self?.vocabBookRepository.readActiveBook() }
            .bind(with: self) { owner, book in
                let wordList = book.vocabList.reversed()

                let histories = owner.learnHistoryRepository.fetchAllHistory()
                let historiesByWord = Dictionary(grouping: histories, by: { $0.vocabId })
                
                let historyStats = historiesByWord.mapValues { historyModels -> (correct: Int, total: Int) in
                    let correctCount = historyModels.filter { $0.isCorrect }.count
                    return (correct: correctCount, total: historyModels.count)
                }
                
                let displayItems = wordList.map { word -> VocabDisplayInfo in
                    if let stats = historyStats[word.id] {
                        let accuracy = stats.total > 0 ? Double(stats.correct) / Double(stats.total) : 0.0
                        return VocabDisplayInfo(word: word, learningCount: stats.total, accuracy: accuracy)
                    } else {
                        return VocabDisplayInfo(word: word, learningCount: 0, accuracy: 0.0)
                    }
                }
                allWordItems.accept(Array(displayItems))
                
            }.disposed(by: disposeBag)
        
        return Output(
            wordItems: allWordItems.asDriver()
        )
    }
    

}
