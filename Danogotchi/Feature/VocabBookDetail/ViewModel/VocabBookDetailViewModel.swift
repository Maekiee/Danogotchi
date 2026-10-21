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
        let alertMessage: Signal<String>
    }

    func transform(input: Input) -> Output {
        let vocabList = BehaviorRelay<[VocabDisplayInfo]>(value: [])
        let isActiveBook = BehaviorRelay<Bool>(value: false)
        let alertMessage = PublishRelay<String>()

        input.viewWillAppear
            .bind(with: self) { owner, _ in
                do {
                    vocabList.accept(try owner.fetchVocabsUseCase.execute(topic: owner.topic))
                } catch {
                    alertMessage.accept(String(localized: "단어를 불러오지 못했어요. 다시 시도해주세요."))
                }
            }
            .disposed(by: disposeBag)

        input.saveVocabTrigger
            .bind(with: self) { owner, item in
                let isSaved: Bool
                do {
                    isSaved = try owner.toggleSaveVocabUseCase.execute(vocab: item.word)
                } catch {
                    alertMessage.accept(String(localized: "저장하지 못했어요. 다시 시도해주세요."))
                    return
                }
                let updatedList = vocabList.value.map { info -> VocabDisplayInfo in
                    guard info.word.id == item.word.id else { return info }
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
                do {
                    try owner.deleteVocabUseCase.execute(vocab: vocab)
                    vocabList.accept(vocabList.value.filter { $0.word.id != vocab.id })
                } catch {
                    alertMessage.accept(String(localized: "삭제하지 못했어요. 다시 시도해주세요."))
                }
            }
            .disposed(by: disposeBag)

        // 지정에 성공하면 화면에 머문 채 버튼만 "학습중"으로 바뀐다
        input.startLearningTrigger
            .bind(with: self) { owner, _ in
                do {
                    try owner.setActiveBookUseCase.execute(topic: owner.topic)
                    isActiveBook.accept(true)
                } catch {
                    alertMessage.accept(String(localized: "단어장 상태를 변경하거나 불러오지 못했어요. 다시 시도해주세요."))
                }
            }
            .disposed(by: disposeBag)

        input.viewWillAppear
            .bind(with: self) { owner, _ in
                do {
                    isActiveBook.accept(try owner.isActiveBookUseCase.execute(topic: owner.topic))
                } catch {
                    alertMessage.accept(String(localized: "단어장 상태를 변경하거나 불러오지 못했어요. 다시 시도해주세요."))
                }
            }
            .disposed(by: disposeBag)

        return Output(
            vocabList: vocabList.asDriver(),
            isActiveBook: isActiveBook.asDriver(),
            alertMessage: alertMessage.asSignal()
        )
    }
}
