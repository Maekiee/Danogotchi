import Foundation
import RxSwift
import RxCocoa

final class CreateWordViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()

    private let vocabItem: CreateVocab?
    private let vocabBookRepository: VocabBookRepository
    private let vocabRepository: VocabRepository
    private let userInfoManager = UserInfoManager.shared

    init(
        vocabItem: CreateVocab? = nil,
        vocabBookRepository: VocabBookRepository,
        vocabRepository: VocabRepository
    ) {
        self.vocabItem = vocabItem
        self.vocabBookRepository = vocabBookRepository
        self.vocabRepository = vocabRepository
    }
    
    
    struct Input {
        let vocabBookTitleTextField: Observable<String>
        let vocabTextField: Observable<String>
        let meanTextField: Observable<String>
        let savedButtonTapped: Observable<Void>
    }
    
    struct Output {
        let isValidSave: Driver<Bool>
        let resetTrigger: Signal<Void>
        let bookTitle: Driver<String>
        let meanText: Driver<String>
        let wordTextFieldText: Driver<String>
    }
    
    func transform(input: Input) -> Output {
        let validWord = BehaviorRelay<String>(value: "")
        let isValidSaved = BehaviorRelay<Bool>(value: false)
        let meanText = BehaviorRelay<String>(value: "")
        let resetTrigger = PublishRelay<Void>()
        let bookTitleText = BehaviorRelay<String>(value: "")
        let actionType = BehaviorRelay<EntryPoint>(value: .add)
        
        if let item = vocabItem {
            bookTitleText.accept(item.bookTitle)
            validWord.accept(item.word)
            meanText.accept(item.meaning)
            actionType.accept(item.actionType)
        }
        
        // 단어장 이름
        let wordBookTitle = Observable.merge(
            bookTitleText.asObservable(),
            input.vocabBookTitleTextField
                .skip(1)
        )
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .share(replay: 1, scope: .whileConnected)
        
        
        
        // 단어
        input.vocabTextField
            .skip(1)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .bind(to: validWord)
            .disposed(by: disposeBag)

        // 뜻
        input.meanTextField
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .bind(to: meanText)
            .disposed(by: disposeBag)

        // 단어장 유효성 검사
        let allInputData = Observable.combineLatest(
            validWord,
//            wordBookTitle,
            meanText)

        allInputData
            .map {  word, mean in
                let hasMeaning = !mean.isEmpty
                let hasWord = !word.isEmpty
                return hasWord && hasMeaning
//                return !title.isEmpty && !url.isEmpty && !word.isEmpty && hasMeaning
            }.bind(to: isValidSaved)
            .disposed(by: disposeBag)
        
        // 저장 버튼
        input.savedButtonTapped
            .withLatestFrom(allInputData)
            .bind(with: self) { owner, validData in
                let (word, mean) = validData

                let actionType = actionType.value

                owner.saveWord(
                    actionType: actionType,
                    wordBookTitle: "나의 단어장",
                    word: word,
                    meaning: mean)

                meanText.accept("")
                resetTrigger.accept(())
            }.disposed(by: disposeBag)
        
        return Output(
            isValidSave: isValidSaved.asDriver(),
            resetTrigger: resetTrigger.asSignal(),
            bookTitle: bookTitleText.asDriver(onErrorJustReturn: ""),
            meanText: meanText.asDriver(onErrorJustReturn: ""),
            wordTextFieldText: validWord.asDriver(onErrorJustReturn: "")
        )
    }
    
    private func saveWord(actionType: EntryPoint, wordBookTitle: String, word: String, meaning: String) {
        guard let bookId = vocabItem?.vocabBookId else {
            print("Error: vocabBookId가 없습니다.")
            return
        }

        switch actionType {
            // 단어 추가 로직
        case .add:
            _ = vocabBookRepository.addVocab(
                bookId: bookId,
                word: word,
                meaning: meaning,
                originWordId: nil
            )
            userInfoManager.notifyWordBookUpdate()
            // 단어 수정 로직
        case .edit:
            // 단어 수정
            guard let vocabId = vocabItem?.vocabId else { return }
            vocabRepository.updateVocab(id: vocabId, word: word, meaning: meaning)
            userInfoManager.notifyWordBookUpdate()
        }
    }
}
