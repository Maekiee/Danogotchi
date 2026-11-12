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
    private var loadTask: Task<Void, Never>?
    let key: VocabBookKey
    var topic: BookTopic { key.topic }

    init(
        key: VocabBookKey,
        fetchVocabsUseCase: FetchVocabsUseCase,
        toggleSaveVocabUseCase: ToggleSaveVocabUseCase,
        deleteVocabUseCase: DeleteVocabUseCase,
        setActiveBookUseCase: SetActiveBookUseCase,
        isActiveBookUseCase: IsActiveBookUseCase
    ) {
        self.key = key
        self.fetchVocabsUseCase = fetchVocabsUseCase
        self.toggleSaveVocabUseCase = toggleSaveVocabUseCase
        self.deleteVocabUseCase = deleteVocabUseCase
        self.setActiveBookUseCase = setActiveBookUseCase
        self.isActiveBookUseCase = isActiveBookUseCase
    }

    deinit {
        loadTask?.cancel()
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
        /// 단어를 읽는 중. 받지 않은 단어장은 서버에서 읽는다
        let isLoadingWords: Driver<Bool>
        /// 학습중 전환(받기 포함) 중. 이 동안 학습하기 버튼을 막는다
        let isLoading: Driver<Bool>
        let alertMessage: Signal<String>
    }

    func transform(input: Input) -> Output {
        let vocabList = BehaviorRelay<[VocabDisplayInfo]>(value: [])
        let isActiveBook = BehaviorRelay<Bool>(value: false)
        let isLoadingWords = BehaviorRelay<Bool>(value: false)
        let isLoading = BehaviorRelay<Bool>(value: false)
        let alertMessage = PublishRelay<String>()

        // 받지 않은 단어장은 서버에서 읽으므로 이전 조회를 취소하고 새로 시작한다
        input.viewWillAppear
            .bind(with: self) { owner, _ in
                owner.loadTask?.cancel()
                isLoadingWords.accept(true)
                let useCase = owner.fetchVocabsUseCase
                let key = owner.key
                // 이미 받아 둔 단어를 넘겨 다시 나타나도 서버를 다시 읽지 않는다
                let loaded = vocabList.value.map(\.word)
                // owner를 캡처하지 않아 요청 중에도 ViewModel이 해제될 수 있다.
                owner.loadTask = Task { @MainActor in
                    // 취소된 이전 조회가 새 조회의 로딩 표시를 끄지 않게 한다
                    defer { if !Task.isCancelled { isLoadingWords.accept(false) } }
                    do {
                        let items = try await useCase.execute(key: key, loaded: loaded)
                        try Task.checkCancellation()
                        vocabList.accept(items)
                    } catch {
                        guard !Task.isCancelled else { return }
                        alertMessage.accept(String(localized: "단어를 불러오지 못했어요. 다시 시도해주세요."))
                    }
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

        // 학습하기·학습중 토글 — 성공하면 화면에 머문 채 버튼만 바뀐다. 받지 않은 단어장은 받기까지 기다린다
        input.startLearningTrigger
            .filter { !isLoading.value }
            .bind(with: self) { owner, _ in
                // 로딩 표시를 동기로 켜 중복 요청을 막는다
                isLoading.accept(true)
                let useCase = owner.setActiveBookUseCase
                let key = owner.key
                let isActive = !isActiveBook.value
                // 화면에 보인 단어를 그대로 저장해 서버를 다시 읽지 않는다
                let loaded = vocabList.value.map(\.word)
                // 화면을 떠나도 받기는 끝까지 진행해 저장하므로 취소하지 않는다 — Library는 변경 신호로 갱신된다
                Task { @MainActor in
                    do {
                        try await useCase.execute(key: key, isActive: isActive, loaded: loaded)
                        isActiveBook.accept(isActive)
                    } catch {
                        alertMessage.accept(String(localized: "단어장 상태를 변경하거나 불러오지 못했어요. 다시 시도해주세요."))
                    }
                    isLoading.accept(false)
                }
            }
            .disposed(by: disposeBag)

        input.viewWillAppear
            .bind(with: self) { owner, _ in
                do {
                    isActiveBook.accept(try owner.isActiveBookUseCase.execute(key: owner.key))
                } catch {
                    alertMessage.accept(String(localized: "단어장 상태를 변경하거나 불러오지 못했어요. 다시 시도해주세요."))
                }
            }
            .disposed(by: disposeBag)

        return Output(
            vocabList: vocabList.asDriver(),
            isActiveBook: isActiveBook.asDriver(),
            isLoadingWords: isLoadingWords.asDriver(),
            isLoading: isLoading.asDriver(),
            alertMessage: alertMessage.asSignal()
        )
    }
}
