import Foundation
import RxSwift
import RxCocoa


final class ExploreVocabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let fetchVocabsUseCase: FetchVocabsUseCase
    private let startQuizUseCase: StartQuizUseCase
    private let toggleSaveVocabUseCase: ToggleSaveVocabUseCase

    /// 표시 순서를 고정하는 셔플 결과. 같은 단어 구성이면 재조회해도 이 순서를 재사용한다.
    private var shuffledOrder: [UUID] = []

    init(
        fetchVocabsUseCase: FetchVocabsUseCase,
        startQuizUseCase: StartQuizUseCase,
        toggleSaveVocabUseCase: ToggleSaveVocabUseCase
    ) {
        self.fetchVocabsUseCase = fetchVocabsUseCase
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

        let viewRefreshTrigger = input.viewWillAppear.startWith(())

        // 트리거마다 CoreData에서 다시 읽는다 — 단어 추가/삭제가 즉시 반영되도록
        Observable.merge(fetchVocabsUseCase.activeBookChanged, viewRefreshTrigger)
            .flatMapLatest { [weak self] _ -> Observable<(bookType: BookTopic, items: [VocabDisplayInfo])> in
                guard let self else { return .empty() }
                return fetchVocabsUseCase.executeActive()
            }
            .bind(with: self) { owner, content in
                allWordItems.accept(owner.shuffledItems(content.items))
                // 나의 단어장을 학습중이면 저장할 곳이 없다
                showsSaveButton.accept(content.bookType != .myBook)
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

    /// 단어장 앞쪽 단어만 반복 노출되지 않도록 무작위로 섞는다.
    /// 단어 구성이 그대로면 기존 순서를 유지한다 — 퀴즈·라이브러리에서 돌아올 때 카드가 재배치되지 않도록.
    private func shuffledItems(_ items: [VocabDisplayInfo]) -> [VocabDisplayInfo] {
        let itemsById = Dictionary(uniqueKeysWithValues: items.map { ($0.word.id, $0) })

        if shuffledOrder.count == items.count {
            let kept = shuffledOrder.compactMap { itemsById[$0] }
            if kept.count == items.count { return kept }
        }

        let shuffled = items.shuffled()
        shuffledOrder = shuffled.map(\.word.id)
        return shuffled
    }
}
