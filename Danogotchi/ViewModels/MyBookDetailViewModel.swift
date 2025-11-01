import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class MyBookDetailViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    private let wordBookRepo = WordBookRepository()
    private let wordRepo = WordRepository()
    private let learningHistoryRepo = LearningHistoryRepository()
    
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let deleteWordTrigger: Observable<Word>
    }
    
    struct Output {
        let wordList: Driver<[WordDisplayInfo]>
    }
    
    func transform(input: Input) -> Output {
        let wordList = BehaviorRelay<[WordDisplayInfo]>(value: [])
        
        input.viewWillAppear
            .take(1)
            .bind(with: self) { owner, _ in
                if let wordBookId = owner.userInfo.selectedBookId,
                   let bookId = try? ObjectId(string: wordBookId) {
                    
                    let myWordList = owner.wordBookRepo.fetchWordsInWordBook(id: bookId).reversed()
                    let histories = owner.learningHistoryRepo.fetchAllHistory()
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
            }.disposed(by: disposeBag)
        
        
        
        input.deleteWordTrigger
            .bind(with: self) { owner, wordItem in
                // UI에서 지우기
                let filteredList = wordList.value.filter { $0.word.id != wordItem.id }
                wordList.accept(filteredList)
                
                // 디비에서 지우기
                let wordId = try! ObjectId(string: wordItem.id)
                owner.wordRepo.delete(id: wordId)
                
                
                // 학습중인 단어장이 나의 단어장 일때 동작
                owner.userInfo.clearQuizState()
            }.disposed(by: disposeBag)
        
        
        return Output(
            wordList: wordList.asDriver()
        )
    }
}
