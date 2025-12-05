import Foundation
import RxSwift
import RxCocoa
import RealmSwift


final class WordTabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    
    private let userInfo = UserInfoManager.shared
    
    private let wordRepo: WordRepositoryProtocol
    private let learningHistoryRepo: LearningHistoryRepositoryProtocol
    
    init(
        wordRepo: WordRepositoryProtocol = WordRepository(),
        learningHistoryRepo: LearningHistoryRepositoryProtocol = LearningHistoryRepository()
    ) {
        self.wordRepo = wordRepo
        self.learningHistoryRepo = learningHistoryRepo
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
        
        // 최종적으로 UI에 바인딩될 WordDisplayInfo 배열
        let allWordItems = BehaviorRelay<[WordDisplayInfo]>(value: [])
        
        let bookChangedTrigger = activeBookRelay.compactMap { $0 }.map { _ in () }
    
        let viewRefreshTrigger = input.viewWillAppear.startWith(())
        
        Observable.merge(bookChangedTrigger, viewRefreshTrigger)
            .withLatestFrom(activeBookRelay.compactMap { $0 })
            .bind(with: self) { owner, book in
                
                let wordList = book.wordList.reversed()
                
                let histories = owner.learningHistoryRepo.fetchAllHistory()
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

        
        // --- 3. 단어 삭제 로직 ---
        
//        input.selectedWordCard
//            .withLatestFrom(activeBookSourceRelay.compactMap { $0 }) { ($0, $1) } // (삭제할 Word, 단어장 Source)
//            .bind(with: self) { owner, data in
//                let (wordCard, source) = data
//                
//                // 추천 단어장(.recommended)인 경우 삭제를 막음
//                guard case .realm(_) = source else {
//                    ToastManager.shared.show("추천 단어장의 단어는 삭제할 수 없습니다.")
//                    return
//                }
//                
//                // 1. UI(Relay)에서 지우기
//                let filteredList = allWordItems.value.filter { $0.word.id != wordCard.id }
//                allWordItems.accept(filteredList)
//                
//                // 2. DB에서 지우기
//                let wordId = try! ObjectId(string: wordCard.id)
//                owner.wordRepo.delete(id: wordId)
//                
//                // 3. ActiveLearningManager 캐시에서 지우기
//                ActiveLearningManager.shared.removeWordFromActiveBook(wordId: wordCard.id)
//
//                // 4. 퀴즈 상태 초기화
//                owner.userInfo.clearQuizState()
//                
//            }.disposed(by: disposeBag)

        
        // --- 4. Output 바인딩 ---
        
        // currentWordbook 및 bookTitle 관련 로직 제거
        
        return Output(
            wordItems: allWordItems.asDriver()
        )
    }
    

}
