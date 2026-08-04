import Foundation
import RxSwift
import RxCocoa

final class AddVocabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let addVocabUseCase: AddVocabUseCase
    private let updateVocabUseCase: UpdateVocabUseCase
    private let editingVocab: Vocab?

    init(
        addVocabUseCase: AddVocabUseCase,
        updateVocabUseCase: UpdateVocabUseCase,
        editingVocab: Vocab? = nil
    ) {
        self.addVocabUseCase = addVocabUseCase
        self.updateVocabUseCase = updateVocabUseCase
        self.editingVocab = editingVocab
    }

    var isEditing: Bool { editingVocab != nil }

    /// 수정 모드 진입 시 화면에 채울 초기값. 추가 모드면 nil.
    var initialForm: (word: String, meaning: String, partOfSpeechIndex: Int)? {
        guard let vocab = editingVocab else { return nil }
        let index = vocab.partOfSpeech.flatMap { PartOfSpeech.allCases.firstIndex(of: $0) } ?? 0
        return (vocab.word, vocab.meaning, index)
    }

    struct Input {
        let wordTextField: Observable<String>
        let meaningTextField: Observable<String>
        let partOfSpeechSegment: Observable<Int>
        let savedButtonTapped: Observable<Void>
    }

    struct Output {
        let isValidSave: Driver<Bool>
        let resetTrigger: Signal<Void>
        let editCompleted: Signal<Void>
    }

    func transform(input: Input) -> Output {
        let wordText = BehaviorRelay<String>(value: "")
        let meaningText = BehaviorRelay<String>(value: "")
        let partOfSpeech = BehaviorRelay<PartOfSpeech>(value: PartOfSpeech.allCases[0])
        let resetTrigger = PublishRelay<Void>()
        let editCompleted = PublishRelay<Void>()

        input.wordTextField
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .bind(to: wordText)
            .disposed(by: disposeBag)

        input.meaningTextField
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .bind(to: meaningText)
            .disposed(by: disposeBag)

        // 세그먼트는 PartOfSpeech.allCases로 만들어지므로 인덱스는 항상 유효하다.
        input.partOfSpeechSegment
            .map { PartOfSpeech.allCases[$0] }
            .bind(to: partOfSpeech)
            .disposed(by: disposeBag)

        let formData = Observable.combineLatest(wordText, meaningText, partOfSpeech)

        let isValidSave = formData
            .map { word, meaning, _ in !word.isEmpty && !meaning.isEmpty }

        // 저장 버튼
        input.savedButtonTapped
            .withLatestFrom(formData)
            .bind(with: self) { owner, validData in
                let (word, meaning, selectedPartOfSpeech) = validData

                if let vocab = owner.editingVocab {
                    owner.updateVocabUseCase.execute(
                        id: vocab.id,
                        word: word,
                        meaning: meaning,
                        partOfSpeech: selectedPartOfSpeech
                    )
                    editCompleted.accept(())
                    return
                }

                guard owner.addVocabUseCase.execute(
                    word: word,
                    meaning: meaning,
                    partOfSpeech: selectedPartOfSpeech
                ) != nil else { return }

                wordText.accept("")
                meaningText.accept("")
                partOfSpeech.accept(PartOfSpeech.allCases[0])
                resetTrigger.accept(())
            }.disposed(by: disposeBag)

        return Output(
            isValidSave: isValidSave.asDriver(onErrorJustReturn: false),
            resetTrigger: resetTrigger.asSignal(),
            editCompleted: editCompleted.asSignal()
        )
    }
}
