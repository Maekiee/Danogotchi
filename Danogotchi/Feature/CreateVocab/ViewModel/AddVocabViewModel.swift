import Foundation
import RxSwift
import RxCocoa

final class AddVocabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let addVocabUseCase: AddVocabUseCase

    init(addVocabUseCase: AddVocabUseCase) {
        self.addVocabUseCase = addVocabUseCase
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
    }

    func transform(input: Input) -> Output {
        let wordText = BehaviorRelay<String>(value: "")
        let meaningText = BehaviorRelay<String>(value: "")
        let partOfSpeech = BehaviorRelay<PartOfSpeech>(value: PartOfSpeech.allCases[0])
        let resetTrigger = PublishRelay<Void>()

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
            resetTrigger: resetTrigger.asSignal()
        )
    }
}
