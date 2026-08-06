import Foundation
import RxSwift
import RxCocoa


final class ExploreVocabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let vocabBookRepository: VocabBookRepository
    private let learnHistoryRepository: LearningHistoryRepository
    private let startQuizUseCase: StartQuizUseCase

    init(
        vocabBookRepository: VocabBookRepository,
        learnHistoryRepository: LearningHistoryRepository,
        startQuizUseCase: StartQuizUseCase
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.learnHistoryRepository = learnHistoryRepository
        self.startQuizUseCase = startQuizUseCase
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let startLearningTapped: Observable<Void>
    }

    struct Output {
        let wordItems: Driver<[VocabDisplayInfo]>
        let startQuiz: Signal<QuizData>
        let alertMessage: Signal<String>
    }
    
    func transform(input: Input) -> Output {
        let allWordItems = BehaviorRelay<[VocabDisplayInfo]>(value: [])
        let startQuizRelay = PublishRelay<QuizData>()
        let alertMessageRelay = PublishRelay<String>()

        let bookChangedTrigger = vocabBookRepository.activeBookId.map { _ in () }

        let viewRefreshTrigger = input.viewWillAppear.startWith(())

        // 트리거마다 CoreData에서 다시 읽는다 — 단어 추가/삭제가 즉시 반영되도록
        Observable.merge(bookChangedTrigger, viewRefreshTrigger)
            .compactMap { [weak self] _ in self?.vocabBookRepository.readActiveBook() }
            .bind(with: self) { owner, book in
                let stats = owner.learnHistoryRepository.fetchAllHistory().statsByVocab()
                let displayItems = book.vocabList.reversed()
                    .map { word in VocabDisplayInfo(word: word, stats: stats[word.id]) }
                allWordItems.accept(displayItems)
            }.disposed(by: disposeBag)

        input.startLearningTapped
            .bind(with: self) { owner, _ in
                switch owner.startQuizUseCase.execute() {
                case .success(let quizData):
                    startQuizRelay.accept(quizData)
                case .noWords:
                    alertMessageRelay.accept("학습할 단어가 없습니다.")
                case .notEnoughWords:
                    alertMessageRelay.accept("최소 4개 이상의 단어가 필요합니다.")
                }
            }.disposed(by: disposeBag)

        return Output(
            wordItems: allWordItems.asDriver(),
            startQuiz: startQuizRelay.asSignal(),
            alertMessage: alertMessageRelay.asSignal()
        )
    }
    

}
