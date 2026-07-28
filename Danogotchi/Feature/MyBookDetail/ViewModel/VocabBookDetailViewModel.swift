import Foundation
import RxSwift
import RxCocoa

final class VocabBookDetailViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let fetchVocabsUseCase: FetchVocabsUseCase
    private let toggleSaveVocabUseCase: ToggleSaveVocabUseCase
    private let deleteVocabUseCase: DeleteVocabUseCase
    let topic: BookTopic

    init(
        topic: BookTopic,
        fetchVocabsUseCase: FetchVocabsUseCase,
        toggleSaveVocabUseCase: ToggleSaveVocabUseCase,
        deleteVocabUseCase: DeleteVocabUseCase
    ) {
        self.topic = topic
        self.fetchVocabsUseCase = fetchVocabsUseCase
        self.toggleSaveVocabUseCase = toggleSaveVocabUseCase
        self.deleteVocabUseCase = deleteVocabUseCase
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let saveVocabTrigger: Observable<VocabDisplayInfo>
        let deleteVocabTrigger: Observable<Vocab>
    }
    
    struct Output {
        let vocabList: Driver<[VocabDisplayInfo]>
    }
    
    func transform(input: Input) -> Output {
        let vocabList = BehaviorRelay<[VocabDisplayInfo]>(value: [])

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

        return Output(vocabList: vocabList.asDriver())
    }
}
