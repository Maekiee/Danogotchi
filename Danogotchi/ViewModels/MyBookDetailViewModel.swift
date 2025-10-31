import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class MyBookDetailViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    private let wordBookRepo = WordBookRepository()
    private let learningHistoryRepo = LearningHistoryRepository()
    
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let wordList: Driver<[WordDisplayInfo]>
    }
    
    func transform(input: Input) -> Output {
        let wordList = BehaviorRelay<[WordDisplayInfo]>(value: [])
        
        if let wordBookId = userInfo.selectedBookId,
           let bookId = try? ObjectId(string: wordBookId) {
            
            let myWordList = wordBookRepo.fetchWordsInWordBook(id: bookId).reversed()
            let histories = learningHistoryRepo.fetchAllHistory()
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
            
        }
        
        
        return Output(
            wordList: wordList.asDriver()
        )
    }
}
