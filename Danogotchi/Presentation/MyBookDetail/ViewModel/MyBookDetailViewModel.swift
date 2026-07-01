import Foundation
import RxSwift
import RxCocoa

final class MyBookDetailViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared

    private let vocabBookRepository: VocabBookRepository
    private let vocabRepository: VocabRepository
    private let learningHistoryRepository: VocabLearningHistoryRepository

    private let myBookId = BehaviorRelay<UUID?>(value: nil)

    init(
        vocabBookRepository: VocabBookRepository,
        vocabRepository: VocabRepository,
        learningHistoryRepository: VocabLearningHistoryRepository
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.vocabRepository = vocabRepository
        self.learningHistoryRepository = learningHistoryRepository
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let deleteWordTrigger: Observable<Vocab>
    }

    struct Output {
        let wordList: Driver<[WordDisplayInfo]>
        let myBookId: Observable<UUID?>
    }
    
    func transform(input: Input) -> Output {
        let wordList = BehaviorRelay<[WordDisplayInfo]>(value: [])
        
        input.viewWillAppear
            .bind(with: self) { owner, _ in
                
                guard let myBook = owner.vocabBookRepository.readAllBooks(type: .mine).first else {
                    // "나의 단어장"이 없는 경우 빈 배열 처리
                    wordList.accept([])
                    owner.myBookId.accept(nil)
                    return
                }

                let bookId = myBook.id
                owner.myBookId.accept(bookId)

                let myWordList = owner.vocabBookRepository.fetchVocabs(inBookId: bookId).reversed()
                let histories = owner.learningHistoryRepository.fetchAllHistory()
                let historiesByVocab = Dictionary(grouping: histories, by: { $0.vocabId })
                let historyStats = historiesByVocab.mapValues { historyModels -> (correct: Int, total: Int) in
                    let correctCount = historyModels.filter { $0.isCorrect }.count
                    return (correct: correctCount, total: historyModels.count)
                }
                let displayItems = myWordList.map { vocab -> WordDisplayInfo in
                    if let stats = historyStats[vocab.id] {
                        let accuracy = stats.total > 0 ? Double(stats.correct) / Double(stats.total) : 0.0
                        return WordDisplayInfo(word: vocab, learningCount: stats.total, accuracy: accuracy)
                    } else {
                        return WordDisplayInfo(word: vocab, learningCount: 0, accuracy: 0.0)
                    }
                }
                wordList.accept(Array(displayItems))
                
            }.disposed(by: disposeBag)
        
        
        
        input.deleteWordTrigger
            .bind(with: self) { owner, vocabItem in
                // UI에서 지우기
                let filteredList = wordList.value.filter { $0.word.id != vocabItem.id }
                wordList.accept(filteredList)

                // 디비에서 지우기
                owner.vocabRepository.deleteVocab(id: vocabItem.id)


                if let activeBookId = UserInfoManager.shared.activeBookIdentifier?.id,
                   let activeMyBookId = owner.myBookId.value?.uuidString {

                    if activeBookId == activeMyBookId {
                        UserInfoManager.shared.clearQuizState()
                    }
                }
            }.disposed(by: disposeBag)
        
        
        return Output(
            wordList: wordList.asDriver(),
            myBookId: myBookId.asObservable()
        )
    }
}
