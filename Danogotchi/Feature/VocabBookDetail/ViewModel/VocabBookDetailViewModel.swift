import Foundation
import RxSwift
import RxCocoa

final class VocabBookDetailViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let fetchVocabsUseCase: FetchVocabsUseCase
    private let toggleSaveVocabUseCase: ToggleSaveVocabUseCase
    private let deleteVocabUseCase: DeleteVocabUseCase
    private let setActiveBookUseCase: SetActiveBookUseCase
    private let isActiveBookUseCase: IsActiveBookUseCase
    let topic: BookTopic

    init(
        topic: BookTopic,
        fetchVocabsUseCase: FetchVocabsUseCase,
        toggleSaveVocabUseCase: ToggleSaveVocabUseCase,
        deleteVocabUseCase: DeleteVocabUseCase,
        setActiveBookUseCase: SetActiveBookUseCase,
        isActiveBookUseCase: IsActiveBookUseCase
    ) {
        self.topic = topic
        self.fetchVocabsUseCase = fetchVocabsUseCase
        self.toggleSaveVocabUseCase = toggleSaveVocabUseCase
        self.deleteVocabUseCase = deleteVocabUseCase
        self.setActiveBookUseCase = setActiveBookUseCase
        self.isActiveBookUseCase = isActiveBookUseCase
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let saveVocabTrigger: Observable<VocabDisplayInfo>
        let deleteVocabTrigger: Observable<Vocab>
        let startLearningTrigger: Observable<Void>
    }

    struct Output {
        let vocabList: Driver<[VocabDisplayInfo]>
        let isActiveBook: Driver<Bool>
    }

    func transform(input: Input) -> Output {
        let vocabList = BehaviorRelay<[VocabDisplayInfo]>(value: [])
        let isActiveBook = BehaviorRelay<Bool>(value: false)

        input.viewWillAppear
            .flatMapLatest { [weak self] _ -> Observable<[VocabDisplayInfo]> in
                guard let self else { return .just([]) }
                return fetchVocabsUseCase.execute(topic: self.topic)
            }
            .bind(to: vocabList)
            .disposed(by: disposeBag)

        input.saveVocabTrigger
            .flatMap { [weak self] item -> Observable<(UUID, Bool)> in
                guard let self else { return .empty() }
                return toggleSaveVocabUseCase.execute(vocab: item.word)
                    .map { (item.word.id, $0) }
            }
            .bind { result in
                let (vocabId, isSaved) = result
                let updatedList = vocabList.value.map { info -> VocabDisplayInfo in
                    guard info.word.id == vocabId else { return info }
                    return VocabDisplayInfo(
                        word: info.word,
                        learningCount: info.learningCount,
                        accuracy: info.accuracy,
                        isSaved: isSaved
                    )
                }
                vocabList.accept(updatedList)
            }
            .disposed(by: disposeBag)

        input.deleteVocabTrigger
            .bind(with: self) { owner, vocab in
                vocabList.accept(vocabList.value.filter { $0.word.id != vocab.id })
                owner.deleteVocabUseCase.execute(vocab: vocab)
            }
            .disposed(by: disposeBag)

        // 지정에 성공하면 화면에 머문 채 버튼만 "학습중"으로 바뀐다
        input.startLearningTrigger
            .flatMapLatest { [weak self] _ -> Observable<Bool> in
                guard let self else { return .empty() }
                return setActiveBookUseCase.execute(topic: self.topic)
            }
            .filter { $0 } // 실패(false)는 흘리지 않는다 — 버튼 상태 유지
            .bind(to: isActiveBook)
            .disposed(by: disposeBag)

        input.viewWillAppear
            .flatMapLatest { [weak self] _ -> Observable<Bool> in
                guard let self else { return .empty() }
                return isActiveBookUseCase.execute(topic: self.topic)
            }
            .bind(to: isActiveBook)
            .disposed(by: disposeBag)

        return Output(
            vocabList: vocabList.asDriver(),
            isActiveBook: isActiveBook.asDriver()
        )
    }
}
