import Foundation
import RxSwift
import RxCocoa


final class ExploreVocabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let vocabBookRepository: VocabBookRepository
    private let learnHistoryRepository: LearningHistoryRepository
    private let startQuizUseCase: StartQuizUseCase
    private let toggleSaveVocabUseCase: ToggleSaveVocabUseCase

    init(
        vocabBookRepository: VocabBookRepository,
        learnHistoryRepository: LearningHistoryRepository,
        startQuizUseCase: StartQuizUseCase,
        toggleSaveVocabUseCase: ToggleSaveVocabUseCase
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.learnHistoryRepository = learnHistoryRepository
        self.startQuizUseCase = startQuizUseCase
        self.toggleSaveVocabUseCase = toggleSaveVocabUseCase
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let startLearningTapped: Observable<Void>
        let saveVocabTrigger: Observable<VocabDisplayInfo>
    }

    struct Output {
        let wordItems: Driver<[VocabDisplayInfo]>
        let showsSaveButton: Driver<Bool>
        let startQuiz: Signal<QuizData>
        let alertMessage: Signal<String>
    }

    func transform(input: Input) -> Output {
        let allWordItems = BehaviorRelay<[VocabDisplayInfo]>(value: [])
        let showsSaveButton = BehaviorRelay<Bool>(value: false)
        let startQuizRelay = PublishRelay<QuizData>()
        let alertMessageRelay = PublishRelay<String>()

        let bookChangedTrigger = vocabBookRepository.activeBookId.map { _ in () }

        let viewRefreshTrigger = input.viewWillAppear.startWith(())

        // 트리거마다 CoreData에서 다시 읽는다 — 단어 추가/삭제가 즉시 반영되도록
        Observable.merge(bookChangedTrigger, viewRefreshTrigger)
            .compactMap { [weak self] _ in self?.vocabBookRepository.readActiveBook() }
            .bind(with: self) { owner, book in
                let stats = owner.learnHistoryRepository.fetchAllHistory().statsByVocab()
                let savedIDs = owner.savedSourceIDs(activeBook: book)
                let displayItems = book.vocabList.reversed()
                    .map { word in
                        VocabDisplayInfo(
                            word: word,
                            stats: stats[word.id],
                            isSaved: savedIDs.contains(word.id)
                        )
                    }
                allWordItems.accept(displayItems)
                // 나의 단어장을 학습중이면 저장할 곳이 없다
                showsSaveButton.accept(book.bookType != .myBook)
            }.disposed(by: disposeBag)

        input.saveVocabTrigger
            .flatMap { [weak self] item -> Observable<(UUID, Bool)> in
                guard let self else { return .empty() }
                return toggleSaveVocabUseCase.execute(vocab: item.word)
                    .map { (item.word.id, $0) }
            }
            .bind { result in
                let (vocabId, isSaved) = result
                let updatedList = allWordItems.value.map { info -> VocabDisplayInfo in
                    guard info.word.id == vocabId else { return info }
                    return VocabDisplayInfo(
                        word: info.word,
                        learningCount: info.learningCount,
                        accuracy: info.accuracy,
                        isSaved: isSaved
                    )
                }
                allWordItems.accept(updatedList)
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
            showsSaveButton: showsSaveButton.asDriver(),
            startQuiz: startQuizRelay.asSignal(),
            alertMessage: alertMessageRelay.asSignal()
        )
    }

    /// 학습중인 추천 단어장의 단어 중 나의 단어장에 복사돼 있는 원본 id 집합
    private func savedSourceIDs(activeBook: VocabBook) -> Set<UUID> {
        guard activeBook.bookType != .myBook,
              let myBook = vocabBookRepository.readAllBooks(bookType: .myBook).first else { return [] }
        return Set(vocabBookRepository.fetchVocabs(inBookId: myBook.id).compactMap { $0.sourceWordId })
    }
}
